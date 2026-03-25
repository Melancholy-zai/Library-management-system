package com.bookborrow.servlet;

import com.bookborrow.util.DBUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/SearchServlet")
public class SearchServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String searchQuery = request.getParameter("search");
        String category = request.getParameter("category");

        if (searchQuery == null || searchQuery.trim().isEmpty()) {
            response.sendRedirect("user/book_list.jsp?error=" + URLEncoder.encode("请输入搜索关键词", "UTF-8"));
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT * FROM rjgc_books WHERE (title LIKE ? OR isbn LIKE ?)";

            if (category != null && !category.trim().isEmpty()) {
                sql += " AND category = ?";
            }

            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, "%" + searchQuery + "%");
            pstmt.setString(2, "%" + searchQuery + "%");

            if (category != null && !category.trim().isEmpty()) {
                pstmt.setString(3, category);
            }

            ResultSet rs = pstmt.executeQuery();

            // 将搜索结果存储到request属性中
            request.setAttribute("searchResults", rs);
            request.setAttribute("searchQuery", searchQuery);
            request.setAttribute("category", category);

            // 转发到搜索结果页面
            request.getRequestDispatcher("user/book_list.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("user/book_list.jsp?error=" + URLEncoder.encode("搜索失败：" + e.getMessage(), "UTF-8"));
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
