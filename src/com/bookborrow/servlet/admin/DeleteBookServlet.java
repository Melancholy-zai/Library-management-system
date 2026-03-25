package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/admin/deleteBook")
public class DeleteBookServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = parseInt(request.getParameter("id"), -1);
        if (id <= 0) {
            redirectErr(response, request, "参数错误");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            // 如果该书仍有未归还记录，不允许删除
            try (PreparedStatement check = conn.prepareStatement(
                    "SELECT COUNT(*) FROM rjgc_borrow_records WHERE book_id=? AND return_date IS NULL")) {
                check.setInt(1, id);
                ResultSet rs = check.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    redirectErr(response, request, "该书仍有未归还借阅记录，不能删除");
                    return;
                }
            }

            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM rjgc_books WHERE id=?")) {
                ps.setInt(1, id);
                int n = ps.executeUpdate();
                if (n > 0) redirectMsg(response, request, "删除成功");
                else redirectErr(response, request, "未找到该图书");
            }
        } catch (Exception e) {
            redirectErr(response, request, "删除失败：" + e.getMessage());
        }
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private void redirectErr(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/book_manage.jsp?error=" + URLEncoder.encode(msg, "UTF-8"));
    }

    private void redirectMsg(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/book_manage.jsp?msg=" + URLEncoder.encode(msg, "UTF-8"));
    }
}
