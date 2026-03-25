package com.bookborrow.servlet;
// src/com/bookborrow/servlet/OverdueReminderServlet.java (逾期提醒)

import com.bookborrow.util.DBUtil;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/overdueReminderServlet")
public class OverdueReminderServlet extends HttpServlet {
    // DB 连接
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            Connection conn = DBUtil.getConnection();
            String sql = "SELECT id, user_id FROM rjgc_borrow_records WHERE status = '借阅中' AND due_date < CURDATE()";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                int recordId = rs.getInt("id");
                int userId = rs.getInt("user_id");
                sql = "UPDATE rjgc_borrow_records SET status = '逾期' WHERE id = ?";
                PreparedStatement updatePstmt = conn.prepareStatement(sql);
                updatePstmt.setInt(1, recordId);
                updatePstmt.executeUpdate();
                sql = "INSERT INTO rjgc_notifications (user_id, notification_type, title, content, related_record_id) VALUES (?, '逾期提醒', '逾期提醒', '您的图书已逾期，请尽快归还。', ?)";
                updatePstmt = conn.prepareStatement(sql);
                updatePstmt.setInt(1, userId);
                updatePstmt.setInt(2, recordId);
                updatePstmt.executeUpdate();
            }
            response.sendRedirect("admin/borrow_manage.jsp?msg=逾期提醒已发送");
        } catch (SQLException e) {
            response.sendRedirect("admin/borrow_manage.jsp?error=发送失败");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }
}