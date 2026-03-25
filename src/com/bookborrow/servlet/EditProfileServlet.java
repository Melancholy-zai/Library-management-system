// src/com/bookborrow/servlet/EditProfileServlet.java
package com.bookborrow.servlet;

import com.bookborrow.util.DBUtil;
import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet("/editProfileServlet")
@MultipartConfig // 支持文件上传
public class EditProfileServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        if (userId == null) {
            response.sendRedirect("../login.jsp");
            return;
        }

        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String emergency = request.getParameter("emergency");
        String password = request.getParameter("password"); // 新密码（可为空）
        String avatarPath = null;

        // 处理上传头像
        Part avatarPart = request.getPart("avatar");
        if (avatarPart != null && avatarPart.getSize() > 0) {
            // 校验文件类型
            String contentType = avatarPart.getContentType();
            if (!contentType.startsWith("image/")) {
                response.sendRedirect("user/edit_profile.jsp?error=" + java.net.URLEncoder.encode("请上传图片文件", "UTF-8"));
                return;
            }

            // 生成唯一文件名
            String fileName = UUID.randomUUID().toString() + ".jpg";
            String uploadPath = getServletContext().getRealPath("/images/avatars/");

            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // 保存文件
            avatarPart.write(uploadPath + fileName);
            avatarPath = "/images/avatars/" + fileName;
        }

        try (Connection conn = DBUtil.getConnection()) {
            StringBuilder sql = new StringBuilder("UPDATE rjgc_users SET ");
            boolean hasUpdate = false;

            // 更新字段
            if (username != null && !username.trim().isEmpty()) {
                sql.append("username = ?, ");
                hasUpdate = true;
            }
            if (email != null && !email.trim().isEmpty()) {
                sql.append("email = ?, ");
                hasUpdate = true;
            }
            if (phone != null && !phone.trim().isEmpty()) {
                sql.append("phone = ?, ");
                hasUpdate = true;
            }
            if (emergency != null && !emergency.trim().isEmpty()) {
                sql.append("emergency_contact = ?, ");
                hasUpdate = true;
            }
            if (avatarPath != null) {
                sql.append("avatar_url = ?, ");
                hasUpdate = true;
            }
            if (password != null && !password.trim().isEmpty()) {
                // 密码需要二次验证，此处仅示例逻辑
                // 实际应调用验证接口或跳转到确认页面
                sql.append("password = ?, ");
                hasUpdate = true;
            }

            // 添加 WHERE 条件
            if (hasUpdate) {
                sql.setLength(sql.length() - 2); // 移除最后的 ", "
                sql.append(" WHERE id = ?");
            } else {
                response.sendRedirect("user/edit_profile.jsp?msg=" + java.net.URLEncoder.encode("无任何信息更新", "UTF-8"));
                return;
            }

            PreparedStatement pstmt = conn.prepareStatement(sql.toString());
            int paramIndex = 1;

            // 设置参数
            if (username != null && !username.trim().isEmpty()) {
                pstmt.setString(paramIndex++, username);
            }
            if (email != null && !email.trim().isEmpty()) {
                pstmt.setString(paramIndex++, email);
            }
            if (phone != null && !phone.trim().isEmpty()) {
                pstmt.setString(paramIndex++, phone);
            }
            if (emergency != null && !emergency.trim().isEmpty()) {
                pstmt.setString(paramIndex++, emergency);
            }
            if (avatarPath != null) {
                pstmt.setString(paramIndex++, avatarPath);
            }
            if (password != null && !password.trim().isEmpty()) {
                // ⚠️ 实际中应使用加密后的密码
                pstmt.setString(paramIndex++, password);
            }
            pstmt.setInt(paramIndex++, userId);

            pstmt.executeUpdate();

            response.sendRedirect("user/dashboard.jsp?msg=" + java.net.URLEncoder.encode("信息更新成功", "UTF-8"));
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendRedirect("user/edit_profile.jsp?error=" + java.net.URLEncoder.encode("更新失败", "UTF-8"));
        }
    }
}
