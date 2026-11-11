@startuml
title Case 3 - Hai thành viên mượn bản sách cuối cùng

autonumber

participant "Mobile A" as A
participant "Mobile B" as B
participant "Backend API" as API
database "Database" as DB

note over A,DB
  Sách chỉ còn 1 bản
  copiesAvailable = 1

  Hai thành viên đều đủ điều kiện mượn
end note

par Thành viên A gửi yêu cầu
    A -> A: Hiển thị Loading
    A -> API: POST /borrowings\nmemberId=A, bookId=LAST
else Thành viên B gửi yêu cầu
    B -> B: Hiển thị Loading
    B -> API: POST /borrowings\nmemberId=B, bookId=LAST
end

API -> DB: Kiểm tra điều kiện mượn và tồn kho
DB --> API: Cả hai hợp lệ, tồn kho ban đầu = 1

API -> DB: Atomic stock decrement\ncopiesAvailable >= 1

note right of DB
  Database chỉ cho phép
  một giao dịch trừ kho thành công.
  Giao dịch còn lại bị từ chối.
end note

group Request thắng - Ví dụ A
    DB --> API: Trừ kho thành công
    API -> DB: Tạo borrowing cho A\nstatus = BORROWED
    DB --> API: Giao dịch thành công

    API --> A: HTTP 201\nstatus = BORROWED
    A -> A: Emit BorrowingSuccess
    A -> A: Hiển thị mượn sách thành công
end

group Request thua - Ví dụ B
    DB --> API: Không còn đủ tồn kho
    API -> API: Hủy giao dịch của B

    API --> B: HTTP 409 Conflict\nSách vừa được người khác mượn hết
    B -> B: Emit BorrowingFailure
    B -> B: Hiển thị thông báo hết sách
end

== Đồng bộ dữ liệu sau request ==

par Mobile A cập nhật tồn kho
    A -> API: GET /books/:id
    API -> DB: Đọc tồn kho mới nhất
    DB --> API: copiesAvailable = 0
    API --> A: HTTP 200\ncopiesAvailable = 0
    A -> A: Cập nhật danh sách sách
else Mobile B cập nhật tồn kho
    B -> API: GET /books/:id
    API -> DB: Đọc tồn kho mới nhất
    DB --> API: copiesAvailable = 0
    API --> B: HTTP 200\ncopiesAvailable = 0
    B -> B: Hiển thị hết sách\nVô hiệu hóa nút Mượn
end

note over A,DB
  Kết quả cuối cùng:
  - Đúng 1 lượt mượn thành công
  - copiesAvailable = 0
  - Không tạo borrowing cho request thua
  - Hai Mobile đồng bộ dữ liệu từ Backend
end note
@enduml

@startuml
title Case 4 - Trả sách từng phần, quá hạn và tiền phạt

autonumber

actor "Độc giả" as User
participant "Flutter Mobile" as Mobile
participant "Backend API" as API
database "Database" as DB
actor "Thủ thư" as Staff

note over User,DB
  Phiếu mượn đã được phê duyệt:
  - Sách A, B, C đang mượn
  - status = BORROWED
  - Cùng ngày hết hạn
end note

== 1. Xem phiếu mượn ==

User -> Mobile: Mở tab Phiếu nhiều sách
Mobile -> API: GET /borrowing-slips?memberId=...
API -> DB: Lấy danh sách phiếu
DB --> API: Danh sách phiếu
API --> Mobile: HTTP 200

User -> Mobile: Chọn phiếu mượn
Mobile -> API: GET /borrowing-slips/:id
API -> DB: Lấy chi tiết phiếu và items
DB --> API: A, B, C - BORROWING
API --> Mobile: HTTP 200\nstatus = BORROWED

Mobile --> User: Hiển thị 3 sách và hạn trả

== 2. Trả A và B đúng hạn ==

User -> Mobile: Chọn trả A và B
User -> Mobile: Nhấn Xác nhận trả

Mobile -> Mobile: Emit Submitting
Mobile -> API: POST /borrowing-slips/:id/return-items\nitems=[A,B], isPaidNow=false

API -> DB: Kiểm tra phiếu và số lượng cần trả

alt Đủ điều kiện trả
    API -> API: Tính phí trả trễ = 0

    API -> DB: Cập nhật A, B = RETURNED
    API -> DB: Hoàn tồn kho A, B
    API -> DB: Cập nhật phiếu = PARTIAL_RETURNED
    DB --> API: Giao dịch thành công

    API --> Mobile: HTTP 200\nstatus = PARTIAL_RETURNED
    Mobile -> Mobile: Emit Success
    Mobile -> API: GET /borrowing-slips/:id
    API --> Mobile: HTTP 200\nA,B đã trả; C đang mượn
    Mobile --> User: Hiển thị Đã trả một phần

else Phiếu hoặc số lượng không hợp lệ
    API --> Mobile: HTTP 400 / 404 / 409
    Mobile -> Mobile: Emit Failure
    Mobile --> User: Hiển thị lỗi nghiệp vụ
end

== 3. Sách C quá hạn 5 ngày ==

note over User,DB
  Giả lập ngày hiện tại trễ hơn dueDate 5 ngày.
  Khi test dùng dữ liệu test và điều chỉnh dueDate.
end note

User -> Mobile: Mở lại chi tiết phiếu
Mobile -> API: GET /borrowing-slips/:id
API --> Mobile: HTTP 200\nstatus = PARTIAL_RETURNED
Mobile --> User: Cảnh báo sách C quá hạn

User -> Mobile: Chọn trả sách C
User -> Mobile: Xác nhận trả

Mobile -> Mobile: Emit Submitting
Mobile -> API: POST /borrowing-slips/:id/return-items\nitems=[C], isPaidNow=false

API -> DB: Kiểm tra sách C chưa trả
API -> API: Tính ngày quá hạn = 5
API -> API: Tiền phạt = 5 x 5000 x 1

API -> DB: Cập nhật C = RETURNED
API -> DB: Hoàn tồn kho C
API -> DB: Cập nhật phiếu = COMPLETED
API -> DB: totalFine = 25000\nfinePaid = false

DB --> API: Giao dịch thành công
API --> Mobile: HTTP 200\nCOMPLETED, totalFine=25000\nfinePaid=false

Mobile -> Mobile: Emit Success
Mobile -> API: GET /borrowing-slips/:id
API --> Mobile: HTTP 200\nDữ liệu phiếu mới nhất
Mobile --> User: Đã trả hết sách\nCòn nợ phạt 25.000 VNĐ

== 4. Thanh toán tiền phạt ==

User -> Staff: Nộp 25.000 VNĐ tại quầy
Staff -> Mobile: Xác nhận đã thu đủ tiền

Mobile -> Mobile: Emit Submitting
Mobile -> API: POST /borrowing-slips/:id/pay-fine

API -> DB: Kiểm tra totalFine và finePaid

alt Chưa thanh toán
    API -> DB: finePaid = true\nCập nhật finePaidAt
    DB --> API: Cập nhật thành công

    API --> Mobile: HTTP 200\nfinePaid = true
    Mobile -> Mobile: Emit Success
    Mobile -> API: GET /borrowing-slips/:id
    API --> Mobile: HTTP 200\nfinePaid = true
    Mobile --> Staff: Hiển thị Đã thanh toán

else Đã thanh toán hoặc không có tiền phạt
    API --> Mobile: HTTP 400
    Mobile -> Mobile: Emit Failure
    Mobile --> Staff: Hiển thị lỗi nghiệp vụ
end

note over User,DB
  Kết quả cuối cùng:
  - A, B, C đã trả
  - Phiếu COMPLETED
  - totalFine = 25000
  - finePaid = true
  - Tồn kho được cập nhật theo từng đợt trả
end note

@enduml