<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>图书管理</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background: linear-gradient(to bottom, #f8f9fa, #e9ecef); min-height: 100vh; }
        .cardx { border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
        .badge-soft { border-radius: 999px; padding: .35rem .7rem; }
    </style>
</head>
<body>

<jsp:include page="_navbar.jsp"/>

<div class="container my-4">

    <div class="d-flex align-items-center justify-content-between mb-3">
        <h3 class="mb-0"><i class="fa-solid fa-book me-2"></i>图书管理</h3>
        <a class="btn btn-outline-secondary" href="dashboard.jsp"><i class="fa-solid fa-arrow-left me-2"></i>返回仪表盘</a>
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

    <!-- 新增图书 -->
    <div class="card cardx p-3 mb-4">
        <h5 class="mb-3">新增图书</h5>
        <form class="row g-2" action="<%= request.getContextPath() %>/admin/addBook" method="post">
            <div class="col-md-3">
                <input class="form-control" name="title" placeholder="书名" required>
            </div>
            <div class="col-md-2">
                <input class="form-control" name="author" placeholder="作者" required>
            </div>
            <div class="col-md-2">
                <input class="form-control" name="isbn" placeholder="ISBN" required>
            </div>
            <div class="col-md-2">
                <input class="form-control" name="category" placeholder="分类(如: 计算机/文学/历史)">
            </div>
            <div class="col-md-3">
                <input class="form-control" name="publisher" placeholder="出版社">
            </div>

            <div class="col-md-2">
                <input type="date" class="form-control" name="publish_date">
            </div>
            <div class="col-md-2">
                <input type="number" class="form-control" name="total_copies" placeholder="总库存" min="0">
            </div>
            <div class="col-md-2">
                <input type="number" class="form-control" name="available_copies" placeholder="可借数" min="0">
            </div>
            <div class="col-md-3">
                <input class="form-control" name="location" placeholder="馆藏位置(如: A排3架)">
            </div>
            <div class="col-md-3">
                <input class="form-control" name="cover_url" placeholder="封面URL(可选)" value="../images/default-book.jpg">
            </div>

            <div class="col-12 d-flex align-items-center gap-3 mt-1">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="is_hot" id="hotAdd">
                    <label class="form-check-label" for="hotAdd">设为热门</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="is_reserved" id="resAdd">
                    <label class="form-check-label" for="resAdd">标记预约</label>
                </div>

                <button class="btn btn-primary ms-auto"><i class="fa-solid fa-plus me-2"></i>添加</button>
            </div>
        </form>
    </div>

    <!-- 搜索 + 分类筛选 -->
    <%
        String q = request.getParameter("q");
        String cat = request.getParameter("cat");
        if (q == null) q = "";
        if (cat == null) cat = "";

        List<String> categories = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT DISTINCT category FROM rjgc_books WHERE category IS NOT NULL AND category<>'' ORDER BY category")) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) categories.add(rs.getString(1));
        } catch (Exception e) { /* ignore */ }
    %>

    <div class="card cardx p-3 mb-3">
        <form class="row g-2" method="get" action="book_manage.jsp">
            <div class="col-md-6">
                <div class="input-group">
                    <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
                    <input class="form-control" name="q" value="<%= q %>" placeholder="搜索：书名/ISBN/作者">
                </div>
            </div>
            <div class="col-md-4">
                <select class="form-select" name="cat">
                    <option value="">全部分类</option>
                    <% for (String c : categories) { %>
                    <option value="<%= c %>" <%= c.equals(cat) ? "selected" : "" %>><%= c %></option>
                    <% } %>
                </select>
            </div>
            <div class="col-md-2 d-grid">
                <button class="btn btn-dark"><i class="fa-solid fa-filter me-2"></i>筛选</button>
            </div>
        </form>
    </div>

    <!-- 图书列表 -->
    <div class="card cardx p-3">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead>
                <tr>
                    <th>ID</th>
                    <th>书名</th>
                    <th>作者</th>
                    <th>ISBN</th>
                    <th>分类</th>
                    <th>库存</th>
                    <th>热门</th>
                    <th>预约</th>
                    <th class="text-end">操作</th>
                </tr>
                </thead>
                <tbody>
                <%
                    String sql =
                            "SELECT * FROM rjgc_books WHERE 1=1 " +
                                    (q.trim().isEmpty() ? "" : " AND (title LIKE ? OR isbn LIKE ? OR author LIKE ?) ") +
                                    (cat.trim().isEmpty() ? "" : " AND category = ? ") +
                                    " ORDER BY id DESC";

                    try (Connection conn = DBUtil.getConnection();
                         PreparedStatement ps = conn.prepareStatement(sql)) {
                        int idx = 1;
                        if (!q.trim().isEmpty()) {
                            ps.setString(idx++, "%" + q + "%");
                            ps.setString(idx++, "%" + q + "%");
                            ps.setString(idx++, "%" + q + "%");
                        }
                        if (!cat.trim().isEmpty()) ps.setString(idx++, cat);

                        ResultSet rs = ps.executeQuery();
                        boolean has = false;
                        while (rs.next()) {
                            has = true;
                            int id = rs.getInt("id");
                            String title = rs.getString("title");
                            String author = rs.getString("author");
                            String isbn = rs.getString("isbn");
                            String category = rs.getString("category");
                            int total = rs.getInt("total_copies");
                            int available = rs.getInt("available_copies");
                            boolean hot = rs.getInt("is_hot") == 1;
                            boolean reserved = false;
                            try { reserved = rs.getInt("is_reserved") == 1; } catch (Exception ignore) {}
                %>
                <tr
                        data-id="<%= id %>"
                        data-title="<%= title == null ? "" : title %>"
                        data-author="<%= author == null ? "" : author %>"
                        data-isbn="<%= isbn == null ? "" : isbn %>"
                        data-category="<%= category == null ? "" : category %>"
                        data-publisher="<%= rs.getString("publisher") == null ? "" : rs.getString("publisher") %>"
                        data-publish_date="<%= rs.getDate("publish_date") == null ? "" : rs.getDate("publish_date").toString() %>"
                        data-total="<%= total %>"
                        data-available="<%= available %>"
                        data-location="<%= rs.getString("location") == null ? "" : rs.getString("location") %>"
                        data-cover_url="<%= rs.getString("cover_url") == null ? "" : rs.getString("cover_url") %>"
                        data-hot="<%= hot ? "1" : "0" %>"
                        data-reserved="<%= reserved ? "1" : "0" %>"
                >
                    <td><%= id %></td>
                    <td class="fw-semibold"><%= title %></td>
                    <td><%= author %></td>
                    <td><code><%= isbn %></code></td>
                    <td><%= (category == null || category.isEmpty()) ? "-" : category %></td>
                    <td>
                        <span class="badge text-bg-secondary badge-soft">总 <%= total %></span>
                        <span class="badge text-bg-success badge-soft">可借 <%= available %></span>
                    </td>
                    <td>
                        <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/toggleHot">
                            <input type="hidden" name="id" value="<%= id %>">
                            <input type="hidden" name="value" value="<%= hot ? 0 : 1 %>">
                            <button class="btn btn-sm <%= hot ? "btn-warning" : "btn-outline-warning" %>">
                                <i class="fa-solid fa-fire me-1"></i><%= hot ? "热门" : "设热门" %>
                            </button>
                        </form>
                    </td>
                    <td>
                        <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/toggleReserve">
                            <input type="hidden" name="id" value="<%= id %>">
                            <input type="hidden" name="value" value="<%= reserved ? 0 : 1 %>">
                            <button class="btn btn-sm <%= reserved ? "btn-info" : "btn-outline-info" %>">
                                <i class="fa-solid fa-bookmark me-1"></i><%= reserved ? "已预约" : "标记预约" %>
                            </button>
                        </form>
                    </td>
                    <td class="text-end">
                        <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#editModal" onclick="fillEdit(this)">
                            <i class="fa-solid fa-pen-to-square me-1"></i>编辑
                        </button>
                        <form class="d-inline" method="post" action="<%= request.getContextPath() %>/admin/deleteBook" onsubmit="return confirm('确认删除该图书吗？')">
                            <input type="hidden" name="id" value="<%= id %>">
                            <button class="btn btn-sm btn-danger"><i class="fa-solid fa-trash me-1"></i>删除</button>
                        </form>
                    </td>
                </tr>
                <%
                    }
                    if (!has) {
                %>
                <tr><td colspan="9" class="text-center text-muted py-4">暂无数据</td></tr>
                <%
                    }
                } catch (Exception e) {
                %>
                <tr><td colspan="9" class="text-center text-danger py-4">加载失败：<%= e.getMessage() %></td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- 编辑 Modal -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <form method="post" action="<%= request.getContextPath() %>/admin/updateBook">
                <div class="modal-header">
                    <h5 class="modal-title">编辑图书</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="id" id="e_id">

                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label">书名</label>
                            <input class="form-control" name="title" id="e_title" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">作者</label>
                            <input class="form-control" name="author" id="e_author" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">ISBN</label>
                            <input class="form-control" name="isbn" id="e_isbn" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">分类</label>
                            <input class="form-control" name="category" id="e_category">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">出版社</label>
                            <input class="form-control" name="publisher" id="e_publisher">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">出版日期</label>
                            <input type="date" class="form-control" name="publish_date" id="e_publish_date">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">总库存</label>
                            <input type="number" class="form-control" name="total_copies" id="e_total" min="0">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">可借</label>
                            <input type="number" class="form-control" name="available_copies" id="e_available" min="0">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">位置</label>
                            <input class="form-control" name="location" id="e_location">
                        </div>
                        <div class="col-md-12">
                            <label class="form-label">封面URL</label>
                            <input class="form-control" name="cover_url" id="e_cover_url">
                        </div>

                        <div class="col-12 d-flex gap-3 mt-2">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_hot" id="e_hot">
                                <label class="form-check-label" for="e_hot">热门</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_reserved" id="e_reserved">
                                <label class="form-check-label" for="e_reserved">预约</label>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" type="button" data-bs-dismiss="modal">取消</button>
                    <button class="btn btn-primary" type="submit"><i class="fa-solid fa-save me-2"></i>保存</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function fillEdit(btn){
        const tr = btn.closest("tr");
        document.getElementById("e_id").value = tr.dataset.id;
        document.getElementById("e_title").value = tr.dataset.title;
        document.getElementById("e_author").value = tr.dataset.author;
        document.getElementById("e_isbn").value = tr.dataset.isbn;
        document.getElementById("e_category").value = tr.dataset.category;
        document.getElementById("e_publisher").value = tr.dataset.publisher;
        document.getElementById("e_publish_date").value = tr.dataset.publish_date;
        document.getElementById("e_total").value = tr.dataset.total;
        document.getElementById("e_available").value = tr.dataset.available;
        document.getElementById("e_location").value = tr.dataset.location;
        document.getElementById("e_cover_url").value = tr.dataset.cover_url;

        document.getElementById("e_hot").checked = tr.dataset.hot === "1";
        document.getElementById("e_reserved").checked = tr.dataset.reserved === "1";
    }
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
