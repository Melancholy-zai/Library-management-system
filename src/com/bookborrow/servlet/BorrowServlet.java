// src/com/bookborrow/servlet/BorrowServlet.java
package com.bookborrow.servlet;

import com.bookborrow.util.DBUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/borrowServlet")
public class BorrowServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Integer userId = (session == null) ? null : (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login.jsp?error=" +
                    URLEncoder.encode("请先登录", "UTF-8"));
            return;
        }

        String bookIdStr = request.getParameter("bookId");
        if (bookIdStr == null || bookIdStr.isEmpty()) {
            response.sendRedirect("user/book_list.jsp?error=" +
                    URLEncoder.encode("参数错误", "UTF-8"));
            return;
        }

        int bookId = Integer.parseInt(bookIdStr);

        try (Connection conn = DBUtil.getConnection()) {

            /* ===== ① 查询借阅上限 ===== */
            int borrowLimit = 0;
            try (PreparedStatement ps =
                         conn.prepareStatement(
                                 "SELECT borrow_limit FROM rjgc_users WHERE id=?")) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    borrowLimit = rs.getInt("borrow_limit");
                }
            }

            /* ===== ② 查询当前正在借阅数（关键！） ===== */
            int currentBorrowed = 0;
            try (PreparedStatement ps =
                         conn.prepareStatement(
                                 "SELECT COUNT(*) FROM rjgc_borrow_records " +
                                         "WHERE user_id=? AND status IN ('借阅中','逾期')")) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    currentBorrowed = rs.getInt(1);
                }
            }

            if (currentBorrowed >= borrowLimit) {
                response.sendRedirect("user/book_list.jsp?error=" +
                        URLEncoder.encode("已达到借阅上限，请先归还", "UTF-8"));
                return;
            }

            /* ===== ③ 插入借阅记录 ===== */
            conn.setAutoCommit(false);

            try (PreparedStatement ps =
                         conn.prepareStatement(
                                 "INSERT INTO rjgc_borrow_records " +
                                         "(user_id, book_id, apply_date, borrow_date, due_date, status) " +
                                         "VALUES (?, ?, CURDATE(), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), '借阅中')")) {
                ps.setInt(1, userId);
                ps.setInt(2, bookId);
                ps.executeUpdate();
            }

            /* ===== ④ 更新库存 ===== */
            try (PreparedStatement ps =
                         conn.prepareStatement(
                                 "UPDATE rjgc_books " +
                                         "SET available_copies = available_copies - 1 " +
                                         "WHERE id=? AND available_copies > 0")) {
                ps.setInt(1, bookId);
                int updated = ps.executeUpdate();
                if (updated <= 0) {
                    conn.rollback();
                    response.sendRedirect("user/book_list.jsp?error=" +
                            URLEncoder.encode("库存不足", "UTF-8"));
                    return;
                }
            }

            conn.commit();

            response.sendRedirect("user/book_list.jsp?msg=" +
                    URLEncoder.encode("借阅成功", "UTF-8"));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("user/book_list.jsp?error=" +
                    URLEncoder.encode("借阅失败", "UTF-8"));
        }
    }
}
