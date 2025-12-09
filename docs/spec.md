Sổ Hụi – Mobile App (Flutter Project Specification)
1. Mục tiêu dự án

Ứng dụng “Sổ Hụi” nhằm hỗ trợ người dùng quản lý các dây hụi cá nhân: theo dõi kỳ góp, tiền góp, báo cáo tổng hợp và nắm rõ dòng tiền. Ứng dụng hoạt động hoàn toàn offline trong bản đầu tiên.

2. Công nghệ & kiến trúc yêu cầu

Flutter ≥ 3.22

Kiến trúc: MVVM 

State management: Riverpod 

Database local: Drift (sqlite ORM)

Routing: GoRouter

UI: Material 3

App offline-first, single-user

Cấu trúc thư mục gợi ý:

lib/
  core/
  common/
  features/
      hui/
      contributions/
      report/

3. Chức năng phiên bản 1.0
3.1. Quản lý dây hụi

Người dùng có thể:

Tạo dây hụi mới

Chỉnh sửa

Xóa

Xem danh sách tất cả dây hụi

Xem báo cáo tổng quan từng dây

Các thuộc tính của một dây hụi:

Tên dây hụi

Tổng số kỳ

Số thành viên

Mệnh giá góp mỗi kỳ

Loại hụi (hụi không lãi / hụi có lãi)

Ngày bắt đầu

Tần suất kỳ (ngày/tuần/tháng)

Ghi chú (optional)

3.2. Quản lý kỳ góp (contributions)

Ứng dụng tự sinh danh sách kỳ dựa vào:

Ngày bắt đầu

Tần suất

Tổng số kỳ

Người dùng có thể:

Đánh dấu kỳ là đã góp / chưa góp

Nhập số tiền thực góp

Thêm ghi chú cho kỳ

Xem các kỳ trễ hạn

3.3. Báo cáo tổng quan

Tổng đã góp

Tổng còn phải góp

Kỳ nào đã trễ

Dự báo ngày kết thúc

Dòng tiền theo thời gian

4. Luật nghiệp vụ của hai loại hụi
4.1. Hụi không lãi (Hụi chết)

Đặc điểm:

Mỗi kỳ, tất cả thành viên góp số tiền cố định.

Người “hốt” nhận đúng tổng tiền của kỳ.

Không có chuyện đấu giá hoặc ăn lãi.

Dòng tiền: đều, ổn định, không thay đổi qua từng kỳ.

Yêu cầu ứng dụng:

Các kỳ sinh tự động, mệnh giá góp luôn bằng nhau.

Người dùng chỉ đánh dấu “đã góp” hoặc nhập số tiền góp nếu thay đổi.

Báo cáo tính tổng số tiền người dùng đã góp từ đầu đến một thời điểm.

4.2. Hụi có lãi (Hụi sống)

Đặc điểm:

Mỗi kỳ, người muốn hốt phải “ra giá” (đấu giá hụi).

Ai trả mức lãi cao hơn thì được hốt kỳ đó.

Số tiền nhận được = tổng góp – phần lãi bỏ lại cho dây.

Mức lãi thay đổi liên tục từng kỳ.

Người hốt càng sớm thì thường chịu lãi cao.

Yêu cầu ứng dụng:

Trong mỗi kỳ, người dùng được nhập:

Mức lãi của kỳ

Người hốt

Số tiền thực nhận = tổng góp – lãi

Lãi tích lại phải thể hiện trong báo cáo (lãi để lại cho dây).

Dòng tiền biến thiên theo kỳ, cần biểu đồ tổng hợp.

5. UI/UX yêu cầu
Màn hình bắt buộc:

Dashboard

Danh sách dây hụi

Tạo/Chỉnh sửa dây hụi

Chi tiết dây hụi

Danh sách kỳ góp

Màn hình chi tiết một kỳ (ghi chú + lãi + tiền thực nhận với hụi sống)

Màn hình báo cáo tổng quan

Cài đặt (theme, export data - optional)

Yêu cầu UI:

Material 3

Hỗ trợ dark mode

Giao diện tối ưu cho mobile

Animation nhẹ nhàng, không cầu kỳ

6. Yêu cầu kỹ thuật khác

DB migration rõ ràng

Code phải có unit test cơ bản cho:

Model

Drift database

Logic tính lãi & dòng tiền

Copilot Workspace được phép tự sinh folder/file mới

Mỗi thay đổi phải có PR description rõ ràng

Chạy flutter test trước khi gửi PR

7. Tính năng không làm trong v1

Multi-user

Cloud backup

Notification

Export CSV

Quản lý nhiều người góp trong cùng dây

8. Mục tiêu của Copilot Workspace

Copilot phải:

Tự generate toàn bộ UI + DB + model

Tạo đầy đủ logic cho hai loại hụi

Sinh unit test cơ bản

Đảm bảo code chạy được (flutter run) sau khi PR merge

Giữ cấu trúc dự án sạch sẽ, dễ mở rộng