<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>借阅管理</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background: linear-gradient(to bottom, #f8f9fa, #e9ecef); min-height: 100vh; }
        .cardx { border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
    </style>
</head>
<body>

<jsp:include page="_navbar.jsp"/>

<div class="container my-4">
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h3 class="mb-0"><i class="fa-solid fa-clipboard-check me-2"></i>借阅处理</h3>
    </div>

    <%
        String error = request.getParameter("error");
        String msg = request.getParameter("msg");
        if (error != null) {
    %>
    <div class="alert alert-danger"><%= error %></div>
    <% } else if (msg != null) { %>
    <div class="alert alert-success"><%= msg %></div>
    <% } %>

    <div class="card cardx p-3">
        <ul class="nav nav-tabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#t1" type="button">借阅申请</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" data-bs-toggle="tab" data-bs-target="#t2" type="button">借阅中 / 逾期</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" data-bs-toggle="tab" data-bs-target="#t3" type="button">续借申请</button>
            </li>
        </ul>

        <div class="tab-content pt-3">

            <!-- Tab1：借阅申请 -->
            <div class="tab-pane fade show active" id="t1">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>申请ID</th>
                            <th>用户</th>
                            <th>图书</th>
                            <th>申请时间</th>
                            <th>状态</th>
                            <th class="text-end">操作</th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            String sqlReq =
                                    "SELECT r.id, r.request_date, r.status, r.user_id, r.book_id, " +
                                            "u.username, b.title " +
                                            "FROM rjgc_borrow_requests r " +
                                            "LEFT JOIN rjgc_users u ON r.user_id=u.id " +
                                            "LEFT JOIN rjgc_books b ON r.book_id=b.id " +
                                            "WHERE r.status='PENDING' ORDER BY r.request_date DESC";
                            try (Connection conn = DBUtil.getConnection();
                                 PreparedStatement ps = conn.prepareStatement(sqlReq)) {
                                ResultSet rs = ps.executeQuery();
                                boolean has = false;
                                while (rs.next()) {
                                    has = true;
                        %>
                        <tr>
                            <td><%= rs.getInt("id") %></td>
                            <td><%= rs.getString("username") == null ? ("UID:" + rs.getInt("user_id")) : rs.getString("username") %></td>
                            <td class="fw-semibold"><%= rs.getString("title") == null ? ("BID:" + rs.getInt("book_id")) : rs.getString("title") %></td>
                            <td><%= rs.getTimestamp("request_date") %></td>
                            <td><span class="badge text-bg-warning">待审核</span></td>
                            <td class="text-end">
                                <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/approveBorrow">
                                    <input type="hidden" name="requestId" value="<%= rs.getInt("id") %>">
                                    <button class="btn btn-sm btn-success"><i class="fa-solid fa-check me-1"></i>通过</button>
                                </form>
                                <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/rejectBorrow" onsubmit="return confirm('确认拒绝？')">
                                    <input type="hidden" name="requestId" value="<%= rs.getInt("id") %>">
                                    <input type="hidden" name="remark" value="管理员拒绝">
                                    <button class="btn btn-sm btn-outline-danger"><i class="fa-solid fa-xmark me-1"></i>拒绝</button>
                                </form>
                            </td>
                        </tr>
                        <%
                            }
                            if (!has) {
                        %>
                        <tr><td colspan="6" class="text-center text-muted py-4">暂无待审核申请</td></tr>
                        <%
                            }
                        } catch (Exception e) {
                        %>
                        <tr><td colspan="6" class="text-center text-danger py-4">加载失败：<%= e.getMessage() %></td></tr>
                        <%
                            }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Tab2：借阅中/逾期 -->
            <div class="tab-pane fade" id="t2">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>记录ID</th>
                            <th>用户</th>
                            <th>图书</th>
                            <th>借出</th>
                            <th>应还</th>
                            <th>状态</th>
                            <th class="text-end">操作</th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            String sqlRec =
                                    "SELECT br.*, u.username, b.title " +
                                            "FROM rjgc_borrow_records br " +
                                            "LEFT JOIN rjgc_users u ON br.user_id=u.id " +
                                            "LEFT JOIN rjgc_books b ON br.book_id=b.id " +
                                            "WHERE br.return_date IS NULL " +
                                            "ORDER BY br.due_date ASC";
                            try (Connection conn = DBUtil.getConnection();
                                 PreparedStatement ps = conn.prepareStatement(sqlRec)) {
                                ResultSet rs = ps.executeQuery();
                                boolean has = false;
                                while (rs.next()) {
                                    has = true;
                                    Date due = rs.getDate("due_date");
                                    boolean overdue = (due != null && due.before(new java.sql.Date(System.currentTimeMillis())));
                        %>
                        <tr>
                            <td><%= rs.getInt("id") %></td>
                            <td><%= rs.getString("username") == null ? ("UID:" + rs.getInt("user_id")) : rs.getString("username") %></td>
                            <td class="fw-semibold"><%= rs.getString("title") == null ? ("BID:" + rs.getInt("book_id")) : rs.getString("title") %></td>
                            <td><%= rs.getDate("borrow_date") %></td>
                            <td><%= due %></td>
                            <td>
                                <% if (overdue) { %>
                                <span class="badge text-bg-danger">逾期</span>
                                <% } else { %>
                                <span class="badge text-bg-success">借阅中</span>
                                <% } %>
                            </td>
                            <td class="text-end">
                                <% if (overdue) { %>
                                <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/sendOverdueReminder">
                                    <input type="hidden" name="borrowId" value="<%= rs.getInt("id") %>">
                                    <button class="btn btn-sm btn-warning">
                                        <i class="fa-solid fa-bell me-1"></i>发送提醒
                                    </button>
                                </form>
                                <% } else { %>
                                <span class="text-muted">—</span>
                                <% } %>
                            </td>
                        </tr>
                        <%
                            }
                            if (!has) {
                        %>
                        <tr><td colspan="7" class="text-center text-muted py-4">暂无借阅中记录</td></tr>
                        <%
                            }
                        } catch (Exception e) {
                        %>
                        <tr><td colspan="7" class="text-center text-danger py-4">加载失败：<%= e.getMessage() %></td></tr>
                        <%
                            }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Tab3：续借申请 -->
            <div class="tab-pane fade" id="t3">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>续借ID</th>
                            <th>借阅记录</th>
                            <th>用户</th>
                            <th>图书</th>
                            <th>申请时间</th>
                            <th>状态</th>
                            <th class="text-end">操作</th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            String sqlRenew =
                                    "SELECT rr.id AS rid, rr.request_date, rr.status, br.id AS bid, br.user_id, br.book_id, " +
                                            "u.username, b.title " +
                                            "FROM rjgc_renew_requests rr " +
                                            "JOIN rjgc_borrow_records br ON rr.borrow_id=br.id " +
                                            "LEFT JOIN rjgc_users u ON br.user_id=u.id " +
                                            "LEFT JOIN rjgc_books b ON br.book_id=b.id " +
                                            "WHERE rr.status='PENDING' ORDER BY rr.request_date DESC";
                            try (Connection conn = DBUtil.getConnection();
                                 PreparedStatement ps = conn.prepareStatement(sqlRenew)) {
                                ResultSet rs = ps.executeQuery();
                                boolean has = false;
                                while (rs.next()) {
                                    has = true;
                        %>
                        <tr>
                            <td><%= rs.getInt("rid") %></td>
                            <td>#<%= rs.getInt("bid") %></td>
                            <td><%= rs.getString("username") == null ? ("UID:" + rs.getInt("user_id")) : rs.getString("username") %></td>
                            <td class="fw-semibold"><%= rs.getString("title") == null ? ("BID:" + rs.getInt("book_id")) : rs.getString("title") %></td>
                            <td><%= rs.getTimestamp("request_date") %></td>
                            <td><span class="badge text-bg-warning">待处理</span></td>
                            <td class="text-end">
                                <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/handleRenew">
                                    <input type="hidden" name="renewId" value="<%= rs.getInt("rid") %>">
                                    <input type="hidden" name="action" value="approve">
                                    <button class="btn btn-sm btn-success"><i class="fa-solid fa-check me-1"></i>通过</button>
                                </form>
                                <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/handleRenew" onsubmit="return confirm('确认拒绝？')">
                                    <input type="hidden" name="renewId" value="<%= rs.getInt("rid") %>">
                                    <input type="hidden" name="action" value="reject">
                                    <input type="hidden" name="remark" value="管理员拒绝续借">
                                    <button class="btn btn-sm btn-outline-danger"><i class="fa-solid fa-xmark me-1"></i>拒绝</button>
                                </form>
                            </td>
                        </tr>
                        <%
                            }
                            if (!has) {
                        %>
                        <tr><td colspan="7" class="text-center text-muted py-4">暂无待处理续借</td></tr>
                        <%
                            }
                        } catch (Exception e) {
                        %>
                        <tr><td colspan="7" class="text-center text-danger py-4">加载失败：<%= e.getMessage() %></td></tr>
                        <%
                            }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
