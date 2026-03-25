package com.bookborrow.servlet.admin;

import com.bookborrow.util.DBUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/admin/approveBorrow")
public class ApproveBorrowServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int requestId = parseInt(request.getParameter("requestId"), -1);
        if (requestId <= 0) {
            redirectErr(response, request, "参数错误");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);

            // 1) 取申请
            int userId, bookId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT user_id, book_id FROM rjgc_borrow_requests WHERE id=? AND status='PENDING' FOR UPDATE")) {
                ps.setInt(1, requestId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) {
                    conn.rollback();
                    redirectErr(response, request, "申请不存在或已处理");
                    return;
                }
                userId = rs.getInt(1);
                bookId = rs.getInt(2);
            }

            // 2) 资格审核：是否有逾期未还
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM rjgc_borrow_records WHERE user_id=? AND return_date IS NULL AND due_date < CURDATE()")) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    reject(conn, requestId, "存在逾期未还，拒绝借阅");
                    conn.commit();
                    redirectMsg(response, request, "用户存在逾期未还，已自动拒绝");
                    return;
                }
            }

            // 3) 资格审核：未归还数量限制（默认5）
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM rjgc_borrow_records WHERE user_id=? AND return_date IS NULL")) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getInt(1) >= 5) {
                    reject(conn, requestId, "未归还数量达到上限，拒绝");
                    conn.commit();
                    redirectMsg(response, request, "用户未归还数量达到上限，已自动拒绝");
                    return;
                }
            }

            // 4) 图书库存与预约校验
            int available, isReserved;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT available_copies, IFNULL(is_reserved,0) FROM rjgc_books WHERE id=? FOR UPDATE")) {
                ps.setInt(1, bookId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) {
                    reject(conn, requestId, "图书不存在");
                    conn.commit();
                    redirectErr(response, request, "图书不存在");
                    return;
                }
                available = rs.getInt(1);
                isReserved = rs.getInt(2);
            }
            if (available <= 0) {
                reject(conn, requestId, "库存不足");
                conn.commit();
                redirectMsg(response, request, "库存不足，已拒绝");
                return;
            }
            if (isReserved == 1) {
                reject(conn, requestId, "图书已标记预约");
                conn.commit();
                redirectMsg(response, request, "图书已标记预约，已拒绝");
                return;
            }

            // 5) 更新申请为通过
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE rjgc_borrow_requests SET status='APPROVED', review_date=NOW() WHERE id=?")) {
                ps.setInt(1, requestId);
                ps.executeUpdate();
            }

            // 6) 插入借阅记录（默认借30天）
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO rjgc_borrow_records(user_id, book_id, borrow_date, due_date, status) " +
                            "VALUES(?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'BORROWED')")) {
                ps.setInt(1, userId);
                ps.setInt(2, bookId);
                ps.executeUpdate();
            }

            // 7) 扣减库存
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE rjgc_books SET available_copies = available_copies - 1 WHERE id=?")) {
                ps.setInt(1, bookId);
                ps.executeUpdate();
            }

            conn.commit();
            redirectMsg(response, request, "审核通过并已生成借阅记录");
        } catch (Exception e) {
            redirectErr(response, request, "审核失败：" + e.getMessage());
        }
    }

    private void reject(Connection conn, int requestId, String remark) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE rjgc_borrow_requests SET status='REJECTED', review_date=NOW(), remark=? WHERE id=?")) {
            ps.setString(1, remark);
            ps.setInt(2, requestId);
            ps.executeUpdate();
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
