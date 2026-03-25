package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/admin/sendOverdueReminder")
public class SendOverdueReminderServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        int borrowId = parseInt(request.getParameter("borrowId"), -1);
        if (borrowId <= 0) {
            redirectErr(response, request, "参数错误");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);

            int userId;
            String bookTitle;
            Date dueDate;

            // 1) 查借阅记录 + 图书标题（加锁避免并发问题）
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT br.user_id, br.due_date, b.title " +
                            "FROM rjgc_borrow_records br " +
                            "JOIN rjgc_books b ON br.book_id = b.id " +
                            "WHERE br.id = ? FOR UPDATE")) {
                ps.setInt(1, borrowId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        redirectErr(response, request, "借阅记录不存在");
                        return;
                    }
                    userId = rs.getInt("user_id");
                    dueDate = rs.getDate("due_date");
                    bookTitle = rs.getString("title");
                }
            }

            // 2) 生成通知内容
            String notifTitle = "逾期提醒";
            String content = "您借阅的《" + (bookTitle == null ? "未知图书" : bookTitle) + "》已逾期（应还日期："
                    + (dueDate == null ? "未知" : dueDate.toString())
                    + "），请尽快归还或申请续借。";

            // 3) 写入通知表：用你真实字段名
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO rjgc_notifications " +
                            "(user_id, notification_type, title, content, related_record_id, is_read, sent_at) " +
                            "VALUES (?, ?, ?, ?, ?, 0, NOW())")) {
                ps.setInt(1, userId);
                ps.setString(2, "OVERDUE_REMINDER");
                ps.setString(3, notifTitle);
                ps.setString(4, content);
                ps.setInt(5, borrowId); // 这里关联借阅记录id，放到 related_record_id
                ps.executeUpdate();
            }

            // 4) 可选：更新借阅记录状态（注意：你表里没有 last_reminder_at 字段；status 也不是 OVERDUE 英文）
            // 你数据库 rjgc_borrow_records.status 是 enum('待审核','借阅中','已归还','逾期')
            // 所以只更新为中文“逾期”，并且不更新 last_reminder_at（否则也会报 Unknown column）
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE rjgc_borrow_records SET status='逾期' " +
                            "WHERE id=? AND return_date IS NULL")) {
                ps.setInt(1, borrowId);
                ps.executeUpdate();
            }

            conn.commit();
            redirectMsg(response, request, "提醒已发送（已写入通知表）");

        } catch (Exception e) {
            redirectErr(response, request, "发送失败：" + e.getMessage());
        }
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private void redirectErr(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?error=" + URLEncoder.encode(msg, "UTF-8"));
    }

    private void redirectMsg(HttpServletResponse response, HttpServletRequest request, String msg) throws IOException {
        response.sendRedirect(request.getContextPath() + "/admin/borrow_manage.jsp?msg=" + URLEncoder.encode(msg, "UTF-8"));
    }
}
