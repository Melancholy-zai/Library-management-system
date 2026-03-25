package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/admin/rejectBorrow")
public class RejectBorrowServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        int requestId = parseInt(request.getParameter("requestId"), -1);
        String remark = request.getParameter("remark");
        if (remark == null) remark = "管理员拒绝";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE rjgc_borrow_requests SET status='REJECTED', review_date=NOW(), remark=? WHERE id=? AND status='PENDING'")) {
            ps.setString(1, remark);
            ps.setInt(2, requestId);
            int n = ps.executeUpdate();
            if (n > 0) {
                response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?msg=" + URLEncoder.encode("已拒绝", "UTF-8"));
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?error=" + URLEncoder.encode("申请不存在或已处理", "UTF-8"));
            }
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?error=" + URLEncoder.encode("操作失败：" + e.getMessage(), "UTF-8"));
        }
    }

    private int parseInt(String s, int def) { try { return Integer.parseInt(s); } catch (Exception e) { return def; } }
}
