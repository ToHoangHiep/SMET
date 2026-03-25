# Checklist Tích hợp GoRoute cho các màn hình

## Tổng quan
Dự án hiện tại sử dụng `go_router` với ShellRoute cho mentor.

**Đã tích hợp:**
- `/login` → LoginPage
- `/home` → HomePage
- `/` → UserManagementPage (admin)

**ShellRoute cho Mentor:**
- `/mentor/dashboard` → MentorDashboard
- `/mentor/courses` → MentorCourse
- `/mentor/courses/create` → MentorCreateCourse
- `/mentor/courses/:id` → MentorCourseDetail
- `/mentor/courses/:id/edit` → MentorUpdateCourse
- `/mentor/learning-paths` → MentorLearningPath
- `/mentor/learning-paths/create` → MentorCreateLearningPath

---

## Các màn hình đã tích hợp

### 1. Mentor Dashboard ✅
- [x] `mentor_dashboard/mentor_dashboard.dart` (file wrapper)
- [x] `mentor_dashboard/mentor_dashboard_web.dart`
- [x] `mentor_dashboard/mentor_dashboard_mobile.dart`
- [x] `mentor_dashboard/mentor_shell.dart` (ShellRoute component)

### 2. Mentor Course ✅
- [x] `mentor_course/mentor_course.dart` (file wrapper)
- [x] `mentor_course/mentor_course_web.dart`
- [x] `mentor_course/mentor_course_mobile.dart`
- [x] `mentor_course/mentor_course_detail_web.dart`
- [x] `mentor_course/mentor_course_detail_mobile.dart`
- [x] `mentor_course/mentor_create_course_web.dart`
- [x] `mentor_course/mentor_create_course_mobile.dart`
- [x] `mentor_course/mentor_update_course_web.dart`
- [x] `mentor_course/mentor_update_course_mobile.dart`

### 3. Mentor Learning Path ✅
- [x] `mentor_learning_path/mentor_learning_path.dart` (file wrapper)
- [x] `mentor_learning_path/mentor_learning_path_web.dart`
- [x] `mentor_learning_path/mentor_learning_path_mobile.dart`
- [x] `mentor_learning_path/mentor_create_learning_path_web.dart`
- [x] `mentor_learning_path/mentor_create_learning_path_mobile.dart`

---

## Cấu trúc Route Hiện tại

```
/                         → UserManagementPage (admin)
/login                    → LoginPage
/home                    → HomePage

/mentor/dashboard         → MentorDashboard (with Shell)
/mentor/courses           → MentorCourse (with Shell)
/mentor/courses/create    → MentorCreateCourse
/mentor/courses/:id       → MentorCourseDetail
/mentor/courses/:id/edit → MentorUpdateCourse
/mentor/learning-paths              → MentorLearningPath (with Shell)
/mentor/learning-paths/create       → MentorCreateLearningPath
```

---

## Ghi chú

- Sử dụng `ShellRoute` để bọc tất cả các màn hình mentor với `MentorShell` (sidebar điều hướng)
- Sidebar tự động highlight menu item dựa trên path hiện tại
- Các file `*_wrapper.dart` có logic responsive tự động (mobile/web)
- Sử dụng `NoTransitionPage` để tránh animation khi chuyển tab trong sidebar

---

## Cập nhật cuối
- Ngày: 2026-03-18
- Hoàn thành: Tất cả các màn hình mentor đã được tích hợp go_router
