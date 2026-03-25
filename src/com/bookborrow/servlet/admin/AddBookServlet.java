package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/admin/addBook")
public class AddBookServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String title = request.getParameter("title");
        String author = request.getParameter("author");
        String isbn = request.getParameter("isbn");
        String publisher = request.getParameter("publisher");
        String publishDate = request.getParameter("publish_date");
        String category = request.getParameter("category");
        String location = request.getParameter("location");
        String coverUrl = request.getParameter("cover_url");

        int total = parseInt(request.getParameter("total_copies"), 1);
        int available = parseInt(request.getParameter("available_copies"), 1);

        boolean isHot = request.getParameter("is_hot") != null;
        boolean isReserved = request.getParameter("is_reserved") != null;

        if (title == null || title.trim().isEmpty() || author == null || author.trim().isEmpty()
                || isbn == null || isbn.trim().isEmpty()) {
            redirectErr(response, request, "必填项缺失（书名/作者/ISBN）");
            return;
        }

        if (total < 0 || available < 0) {
            redirectErr(response, request, "库存不能为负数");
            return;
        }
        if (available > total) {
            redirectErr(response, request, "可借数量不能大于总库存");
            return;
        }
        if (coverUrl == null || coverUrl.trim().isEmpty()) coverUrl = "../images/default-book.jpg";

        String sql = "INSERT INTO rjgc_books(isbn,title,author,publisher,publish_date,category,total_copies,available_copies,location,is_hot,is_reserved,cover_url) " +
                "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, isbn);
            ps.setString(2, title);
            ps.setString(3, author);
            ps.setString(4, publisher);

            if (publishDate != null && !publishDate.trim().isEmpty()) {
                ps.setDate(5, Date.valueOf(publishDate));
            } else {
                ps.setNull(5, Types.DATE);
            }

            ps.setString(6, category);
            ps.setInt(7, total);
            ps.setInt(8, available);
            ps.setString(9, location);
            ps.setInt(10, isHot ? 1 : 0);
            ps.setInt(11, isReserved ? 1 : 0);
            ps.setString(12, coverUrl);

            ps.executeUpdate();
            redirectMsg(response, request, "添加成功");
        } catch (SQLIntegrityConstraintViolationException dup) {
            redirectErr(response, request, "ISBN 已存在，不能重复添加");
        } catch (Exception e) {
            redirectErr(response, request, "添加失败：" + e.getMessage());
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
