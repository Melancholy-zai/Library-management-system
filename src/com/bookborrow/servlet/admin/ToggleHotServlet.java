package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/admin/toggleHot")
public class ToggleHotServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = parseInt(request.getParameter("id"), -1);
        int value = parseInt(request.getParameter("value"), 0);

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("UPDATE rjgc_books SET is_hot=? WHERE id=?")) {
            ps.setInt(1, value);
            ps.setInt(2, id);
            ps.executeUpdate();
            response.sendRedirect(request.getContextPath() + "/admin/book_manage.jsp?msg=" + URLEncoder.encode("操作成功", "UTF-8"));
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin/book_manage.jsp?error=" + URLEncoder.encode("操作失败：" + e.getMessage(), "UTF-8"));
        }
    }

    private int parseInt(String s, int def) { try { return Integer.parseInt(s); } catch (Exception e) { return def; } }
}
