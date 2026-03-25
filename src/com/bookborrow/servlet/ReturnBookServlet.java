package com.bookborrow.servlet;

import com.bookborrow.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@WebServlet("/returnServlet")
public class ReturnBookServlet extends HttpServlet {

    // 每日罚金（元/天）——想改直接改这里
    private static final double DAILY_FINE = 1.0;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        try {
            // 1️⃣ 登录校验
            HttpSession session = request.getSession(false);
            Integer userId = (session == null) ? null : (Integer) session.getAttribute("userId");
            if (userId == null) {
                response.getWriter().write(json(false, "未登录"));
                return;
            }

            // 2️⃣ 参数校验
            String recordIdStr = request.getParameter("recordId");
            if (recordIdStr == null || recordIdStr.trim().isEmpty()) {
                response.getWriter().write(json(false, "缺少参数 recordId"));
                return;
            }

            int recordId;
            try {
                recordId = Integer.parseInt(recordIdStr);
            } catch (NumberFormatException e) {
                response.getWriter().write(json(false, "recordId 格式错误"));
                return;
            }

            // 3️⃣ 数据库操作
            try (Connection conn = DBUtil.getConnection()) {
                conn.setAutoCommit(false);

                // 🔒 锁定借阅记录
                String selectSql =
                        "SELECT book_id, status, due_date " +
                                "FROM rjgc_borrow_records " +
                                "WHERE id=? AND user_id=? FOR UPDATE";

                PreparedStatement ps = conn.prepareStatement(selectSql);
                ps.setInt(1, recordId);
                ps.setInt(2, userId);
                ResultSet rs = ps.executeQuery();

                if (!rs.next()) {
                    conn.rollback();
                    response.getWriter().write(json(false, "借阅记录不存在"));
                    return;
                }

                String status = rs.getString("status");
                int bookId = rs.getInt("book_id");
                Date dueDateSql = rs.getDate("due_date");

                if (!"借阅中".equals(status) && !"逾期".equals(status)) {
                    conn.rollback();
                    response.getWriter().write(json(false, "当前状态不可归还"));
                    return;
                }

                // 4️⃣ ⭐ 计算逾期罚金（核心）
                double fine = 0.0;
                long overdueDays = 0;

                if (dueDateSql != null) {
                    LocalDate dueDate = dueDateSql.toLocalDate();
                    LocalDate today = LocalDate.now();

                    if (today.isAfter(dueDate)) {
                        overdueDays = ChronoUnit.DAYS.between(dueDate, today);
                        fine = overdueDays * DAILY_FINE;
                    }
                }

                // 5️⃣ 更新借阅记录（状态 + 归还日期 + 罚金）
                String updateRecord =
                        "UPDATE rjgc_borrow_records " +
                                "SET status='已归还', return_date=CURDATE(), renew_fee=? " +
                                "WHERE id=? AND user_id=?";

                PreparedStatement ups1 = conn.prepareStatement(updateRecord);
                ups1.setDouble(1, fine);
                ups1.setInt(2, recordId);
                ups1.setInt(3, userId);
                ups1.executeUpdate();

                // 6️⃣ 图书库存 +1
                String updateBook =
                        "UPDATE rjgc_books " +
                                "SET available_copies = available_copies + 1 " +
                                "WHERE id=?";

                PreparedStatement ups2 = conn.prepareStatement(updateBook);
                ups2.setInt(1, bookId);
                ups2.executeUpdate();

                conn.commit();

                // 7️⃣ 返回结果
                response.getWriter().write(
                        "{"
                                + "\"success\":true,"
                                + "\"message\":\"归还成功"
                                + (fine > 0 ? "，逾期 " + overdueDays + " 天，罚金 " + fine + " 元" : "")
                                + "\","
                                + "\"overdueDays\":" + overdueDays + ","
                                + "\"fine\":" + String.format("%.2f", fine)
                                + "}"
                );
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write(json(false, "服务器异常"));
        }
    }

    private String json(boolean success, String msg) {
        return "{\"success\":" + success + ",\"message\":\"" + safe(msg) + "\"}";
    }

    private String safe(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
