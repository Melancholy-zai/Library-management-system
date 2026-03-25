package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/admin/handleRenew")
public class HandleRenewServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        int renewId = parseInt(request.getParameter("renewId"), -1);
        String action = request.getParameter("action"); // approve / reject
        String remark = request.getParameter("remark");

        if (renewId <= 0 || action == null) {
            redirectErr(response, request, "参数错误");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);

            int borrowId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT borrow_id FROM rjgc_renew_requests WHERE id=? AND status='PENDING' FOR UPDATE")) {
                ps.setInt(1, renewId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) {
                    conn.rollback();
                    redirectErr(response, request, "续借申请不存在或已处理");
                    return;
                }
                borrowId = rs.getInt(1);
            }

            if ("approve".equalsIgnoreCase(action)) {
                // 续借资格：必须未归还
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM rjgc_borrow_records WHERE id=? AND return_date IS NULL FOR UPDATE")) {
                    ps.setInt(1, borrowId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next() && rs.getInt(1) == 0) {
                        // 已归还则拒绝
                        try (PreparedStatement up = conn.prepareStatement(
                                "UPDATE rjgc_renew_requests SET status='REJECTED', processed_date=NOW(), remark=? WHERE id=?")) {
                            up.setString(1, "已归还，不能续借");
                            up.setInt(2, renewId);
                            up.executeUpdate();
                        }
                        conn.commit();
                        redirectMsg(response, request, "该记录已归还，续借已拒绝");
                        return;
                    }
                }

                // 延长 15 天
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE rjgc_borrow_records SET due_date=DATE_ADD(due_date, INTERVAL 15 DAY), renew_count=renew_count+1 " +
                                "WHERE id=? AND return_date IS NULL")) {
                    ps.setInt(1, borrowId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE rjgc_renew_requests SET status='APPROVED', processed_date=NOW(), remark=? WHERE id=?")) {
                    ps.setString(1, remark == null ? "续借通过" : remark);
                    ps.setInt(2, renewId);
                    ps.executeUpdate();
                }

                conn.commit();
                redirectMsg(response, request, "续借已通过（+15天）");
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE rjgc_renew_requests SET status='REJECTED', processed_date=NOW(), remark=? WHERE id=?")) {
                    ps.setString(1, remark == null ? "续借拒绝" : remark);
                    ps.setInt(2, renewId);
                    ps.executeUpdate();
                }
                conn.commit();
                redirectMsg(response, request, "已拒绝续借");
            }

        } catch (Exception e) {
            redirectErr(response, request, "处理失败：" + e.getMessage());
        }
    }

    private int parseInt(String s, int def) { try { return Integer.parseInt(s); } catch (Exception e) { return def; } }

    private void redirectErr(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?error=" + URLEncoder.encode(msg, "UTF-8"));
    }
    private void redirectMsg(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?msg=" + URLEncoder.encode(msg, "UTF-8"));
    }
}
