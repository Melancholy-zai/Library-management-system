package com.bookborrow.servlet;

import com.bookborrow.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/renewServlet")
public class RenewServlet extends HttpServlet {

    private void writeJson(HttpServletResponse response, int httpStatus, String json) throws IOException {
        response.setStatus(httpStatus);
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        response.getWriter().write(json);
    }

    private String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            HttpSession session = request.getSession(false);
            Integer userId = (session == null) ? null : (Integer) session.getAttribute("userId");

            if (userId == null) {
                writeJson(response, 401, "{\"success\":false,\"message\":\"请先登录\"}");
                return;
            }

            String recordIdStr = request.getParameter("recordId");
            if (recordIdStr == null || recordIdStr.trim().isEmpty()) {
                writeJson(response, 400, "{\"success\":false,\"message\":\"缺少参数 recordId\"}");
                return;
            }

            int recordId;
            try {
                recordId = Integer.parseInt(recordIdStr.trim());
            } catch (NumberFormatException nfe) {
                writeJson(response, 400, "{\"success\":false,\"message\":\"recordId 非法\"}");
                return;
            }

            try (Connection conn = DBUtil.getConnection()) {
                conn.setAutoCommit(false);

                // 1) 锁定记录，校验归属&状态
                String qSql = "SELECT id, user_id, status, due_date, renew_count, renew_fee " +
                        "FROM rjgc_borrow_records WHERE id = ? FOR UPDATE";
                Date dueDate;
                int renewCount;
                double renewFee;
                String status;

                try (PreparedStatement qps = conn.prepareStatement(qSql)) {
                    qps.setInt(1, recordId);
                    try (ResultSet rs = qps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            writeJson(response, 404, "{\"success\":false,\"message\":\"借阅记录不存在\"}");
                            return;
                        }

                        int dbUserId = rs.getInt("user_id");
                        if (dbUserId != userId) {
                            conn.rollback();
                            writeJson(response, 403, "{\"success\":false,\"message\":\"无权限操作该记录\"}");
                            return;
                        }

                        status = rs.getString("status");
                        if (!"借阅中".equals(status)) {
                            conn.rollback();
                            writeJson(response, 400, "{\"success\":false,\"message\":\"当前状态不可续借\"}");
                            return;
                        }

                        dueDate = rs.getDate("due_date");
                        if (dueDate == null) {
                            conn.rollback();
                            writeJson(response, 400, "{\"success\":false,\"message\":\"该记录应还日期为空，无法续借\"}");
                            return;
                        }

                        renewCount = rs.getInt("renew_count");
                        renewFee = rs.getDouble("renew_fee");
                    }
                }

                // 2) 费用规则：第1次续借免费；第2次起每次+5
                double thisFee = (renewCount >= 1) ? 5.0 : 0.0;
                int newRenewCount = renewCount + 1;
                double newTotalFee = renewFee + thisFee;

                // 3) 更新
                String uSql = "UPDATE rjgc_borrow_records " +
                        "SET due_date = DATE_ADD(due_date, INTERVAL 30 DAY), " +
                        "    renew_count = ?, renew_fee = ? " +
                        "WHERE id = ? AND user_id = ? AND status='借阅中'";
                try (PreparedStatement ups = conn.prepareStatement(uSql)) {
                    ups.setInt(1, newRenewCount);
                    ups.setDouble(2, newTotalFee);
                    ups.setInt(3, recordId);
                    ups.setInt(4, userId);

                    int updated = ups.executeUpdate();
                    if (updated <= 0) {
                        conn.rollback();
                        writeJson(response, 400, "{\"success\":false,\"message\":\"续借失败：记录状态可能已改变\"}");
                        return;
                    }
                }

                // 4) 读取最新 due_date
                String dSql = "SELECT due_date FROM rjgc_borrow_records WHERE id = ?";
                String newDueDate;
                try (PreparedStatement dps = conn.prepareStatement(dSql)) {
                    dps.setInt(1, recordId);
                    try (ResultSet drs = dps.executeQuery()) {
                        if (!drs.next() || drs.getDate("due_date") == null) {
                            conn.rollback();
                            writeJson(response, 500, "{\"success\":false,\"message\":\"续借后未获取到新的应还日期\"}");
                            return;
                        }
                        newDueDate = drs.getDate("due_date").toString();
                    }
                }

                conn.commit();

                // 下一次续借提示：只要已经续借过一次，下一次肯定收费 5
                double nextFee = (newRenewCount >= 1) ? 5.0 : 0.0;

                String json =
                        "{"
                                + "\"success\":true,"
                                + "\"message\":\"续借成功\","
                                + "\"newDueDate\":\"" + jsonEscape(newDueDate) + "\","
                                + "\"totalFee\":" + String.format("%.1f", newTotalFee) + ","
                                + "\"thisFee\":" + String.format("%.1f", thisFee) + ","
                                + "\"renewCount\":" + newRenewCount + ","
                                + "\"nextFee\":" + String.format("%.1f", nextFee)
                                + "}";

                writeJson(response, 200, json);
            }

        } catch (Exception e) {
            e.printStackTrace();
            writeJson(response, 500, "{\"success\":false,\"message\":\"服务器异常：" + jsonEscape(e.getMessage()) + "\"}");
        }
    }
}
