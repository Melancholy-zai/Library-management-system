// src/com/bookborrow/servlet/FeedbackServlet.java
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
import javax.servlet.http.HttpSession;

@WebServlet("/feedbackServlet")
public class FeedbackServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 设置请求编码
        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        // ① 登录校验（你原来就有，保留）
        if (userId == null) {
            response.sendRedirect("login.jsp?error=" +
                    URLEncoder.encode("请先登录", "UTF-8"));
            return;
        }

        try {
            /* =========================
               ② 新增：bookId 防御校验
               ========================= */
            String bookIdStr = request.getParameter("bookId");
            if (bookIdStr == null || bookIdStr.trim().isEmpty()) {
                response.sendRedirect("user/feedback.jsp?error=" +
                        URLEncoder.encode("请选择要反馈的图书", "UTF-8"));
                return;
            }

            int bookId = Integer.parseInt(bookIdStr);

            /* =========================
               ③ 原有参数解析（未改）
               ========================= */
            int rating = Integer.parseInt(request.getParameter("rating"));
            String comment = request.getParameter("comment");

            /* =========================
               ④ 原有业务校验：是否借阅
               ========================= */
            if (!hasBorrowedBook(userId, bookId)) {
                response.sendRedirect("user/feedback.jsp?error=" +
                        URLEncoder.encode("您未借阅过此图书，无法提交反馈", "UTF-8"));
                return;
            }

            /* =========================
               ⑤ 原有业务校验：是否重复反馈
               ========================= */
            if (hasSubmittedFeedback(userId, bookId)) {
                response.sendRedirect("user/feedback.jsp?error=" +
                        URLEncoder.encode("您已为该图书提交过反馈", "UTF-8"));
                return;
            }

            /* =========================
               ⑥ 插入反馈记录（未改）
               ========================= */
            try (Connection conn = DBUtil.getConnection()) {
                String sql =
                        "INSERT INTO rjgc_feedbacks " +
                                "(user_id, book_id, rating, comment) " +
                                "VALUES (?, ?, ?, ?)";
                PreparedStatement pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, userId);
                pstmt.setInt(2, bookId);
                pstmt.setInt(3, rating);
                pstmt.setString(4, comment);
                pstmt.executeUpdate();
            }

            response.sendRedirect("user/feedback.jsp?msg=" +
                    URLEncoder.encode("反馈提交成功", "UTF-8"));

        } catch (NumberFormatException e) {
            // 防止非法数字（比如手动改表单）
            response.sendRedirect("user/feedback.jsp?error=" +
                    URLEncoder.encode("参数格式错误", "UTF-8"));
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("user/feedback.jsp?error=" +
                    URLEncoder.encode("提交失败，请稍后重试", "UTF-8"));
        }
    }

    // 验证用户是否借阅过该书籍（你原来的，完全没动）
    private boolean hasBorrowedBook(int userId, int bookId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            String sql =
                    "SELECT COUNT(*) " +
                            "FROM rjgc_borrow_records " +
                            "WHERE user_id = ? AND book_id = ? AND status = '已归还'";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            pstmt.setInt(2, bookId);
            ResultSet rs = pstmt.executeQuery();
            rs.next();
            return rs.getInt(1) > 0;
        }
    }

    // 检查是否已提交过反馈（你原来的，完全没动）
    private boolean hasSubmittedFeedback(int userId, int bookId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            String sql =
                    "SELECT COUNT(*) " +
                            "FROM rjgc_feedbacks " +
                            "WHERE user_id = ? AND book_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            pstmt.setInt(2, bookId);
            ResultSet rs = pstmt.executeQuery();
            rs.next();
            return rs.getInt(1) > 0;
        }
    }
}
