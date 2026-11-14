Thứ tự	Screen / nhóm màn	Mức ưu tiên	Mục tiêu redesign
1	BookDetailScreen	P0	Đã duyệt Stitch, đang implement
2	BooksScreen	P0	Catalogue, search, book cards
3	MainScreen / Home	P0	Home mobile-first, navigation
4	BorrowingSlipListScreen	P0	Danh sách phiếu mượn, trạng thái
5	BorrowingSlipDetailScreen	P0	Chi tiết phiếu, role actions, renewal
6	BorrowConfirmScreen	P0	Xác nhận mượn một sách
7	BorrowingSlipConfirmScreen	P0	Xác nhận phiếu nhiều sách, hạn mức
8	MyReservationsScreen	P1	Đặt trước, hủy, phân trang
9	BorrowingSlipReturnScreen	P1	Trả sách, số lượng và tình trạng
10	ProfileScreen + Borrowing Limit	P1	Hồ sơ độc giả, hạn mức, công nợ
11	Login / Register / Forgot Password	P2	Đồng nhất thiết kế auth

Nhóm LIBRARIAN nên có roadmap riêng
Các màn quản lý thủ thư có cách sử dụng khác MEMBER, nên t không muốn ép chung một kiểu bố cục:
- ManageBorrowingSlipsScreen
- PendingBorrowingSlipsScreen
- SlipDecisionDialog
- PaySlipFineScreen
T sẽ thiết kế sau khi hoàn thiện các luồng MEMBER cơ bản, trừ khi m cần demo thủ thư sớm.
Thứ tự triển khai thực tế t muốn đổi một chút
Thay vì cứ lần lượt từng màn theo bảng, t sẽ gom theo user journey, bởi một hành trình mượn sách phải có giao diện nhất quán từ đầu đến cuối.
Journey A — Khám phá và mượn sách
BooksScreen
BookDetail
BorrowConfirm
BorrowResult


Journey B — Theo dõi phiếu mượn
My Borrowings
Slip Detail
Renewal / Cancellation


Journey C — Đặt trước
BookDetail
Reserve Dialog
MyReservations


Journey D — Tài khoản
Profile
Borrowing Limit
Auth


Workflow cho mỗi màn tiếp theo
T vẫn giữ đúng quy trình vừa thử với Book Detail:
1. Antigravity đọc source Flutter và tạo UI Contract.
2. Stitch tạo bản redesign trong cùng project Librio Academic Library App.
3. M review hình ảnh, field, nút, trạng thái, rồi sửa đến khi ưng.
4. Đặt tên bản cuối ScreenName ver final và lưu screen ID.
5. Antigravity dùng Stitch MCP lấy đúng phiên bản đã duyệt và implement Flutter.
6. Chạy flutter analyze, flutter test, kiểm tra responsive và so screenshot Flutter với Stitch.
7. Một commit riêng cho mỗi màn hoặc nhóm component gắn chặt với màn đó.