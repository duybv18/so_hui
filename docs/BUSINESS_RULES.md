# Quy Tắc Nghiệp Vụ - Sổ Hụi

## Tổng quan

Ứng dụng hỗ trợ 2 loại hụi phổ biến ở Việt Nam:
1. **Hụi chết** (Hụi không lãi) - Fixed ROSCA
2. **Hụi sống** (Hụi có lãi) - Interest-based ROSCA

## 1. Hụi Chết (Fixed ROSCA)

### Đặc điểm
- Mỗi kỳ, tất cả thành viên góp số tiền cố định
- Người "hốt" nhận đúng tổng số tiền góp của kỳ đó
- Không có đấu giá hoặc lãi suất
- Dòng tiền ổn định, dễ tính toán

### Công thức tính toán

```dart
// Tổng tiền mỗi kỳ
totalPerPeriod = contributionAmount × numMembers

// Người hốt nhận
amountReceived = totalPerPeriod

// Tổng đã góp (của 1 người)
totalPaid = Σ(actualAmount) for paid contributions

// Tổng còn phải góp
totalRemaining = unpaidCount × contributionAmount
```

### Ví dụ

```
Dây hụi: 10 người, mỗi kỳ góp 1 triệu
Tổng số kỳ: 10
Tần suất: Hàng tháng

Kỳ 1: 10 người góp 1tr, người A hốt nhận 10tr
Kỳ 2: 10 người góp 1tr, người B hốt nhận 10tr
...
Kỳ 10: 10 người góp 1tr, người J hốt nhận 10tr

Tổng mỗi người góp: 10tr
Tổng mỗi người nhận: 10tr
```

### Trong ứng dụng

1. Tạo dây hụi với type = `HuiType.fixed`
2. App tự động sinh `totalPeriods` kỳ góp
3. Mỗi kỳ:
   - User đánh dấu đã góp/chưa góp
   - Nhập số tiền thực góp (mặc định = contributionAmount)
   - Thêm ghi chú nếu cần
4. Không cần nhập thông tin người hốt hoặc lãi suất

## 2. Hụi Sống (Auction-based ROSCA)

### Đặc điểm
- Mỗi kỳ, tất cả thành viên góp số tiền
- Người muốn hốt phải "ra giá" - đấu giá bằng cách chấp nhận bỏ một số tiền (tiền bỏ / bid amount)
- Ai chấp nhận bỏ ra nhiều tiền nhất (giảm giá nhiều nhất) thì được hốt
- **Người chưa hốt (U)** trả: `baseContribution - bidAmount` (giảm giá)
- **Người đã hốt (H)** trả: `baseContribution` (đầy đủ)
- Người hốt nhận: `discounted × (|U| - 1)`
- Tiền dư mỗi kỳ = tổng thu - tiền trả cho người hốt
- Mỗi người chỉ được hốt đúng 1 lần trong suốt dây hụi
- Người cuối cùng hốt tự động với tiền bỏ = 0

### Công thức tính toán

```dart
// Các biến
baseContribution = mệnh giá góp mỗi kỳ
bidAmount = tiền bỏ (số tiền người hốt chấp nhận bỏ ra)
U = số người chưa hốt
H = số người đã hốt

// Thanh toán giảm giá (cho người chưa hốt)
discounted = baseContribution - bidAmount

// Thanh toán đầy đủ (cho người đã hốt)
full = baseContribution

// Tổng thu kỳ này
totalCollected = (discounted × |U|) + (full × |H|)

// Người hốt nhận
payout = discounted × (|U| - 1)

// Tiền dư kỳ này
periodSurplus = totalCollected - payout

// Tổng tiền dư cuối dây
totalSurplus = Σ(periodSurplus for all periods)
```

### Ví dụ chi tiết (10 người, mệnh giá 2 triệu)

```
🔵 Kỳ 1 (Người A hốt, bỏ 300k)
H = {} (chưa ai hốt trước)
U = {A, B, C, D, E, F, G, H, I, J} (10 người)

Thanh toán giảm giá: 2,000,000 - 300,000 = 1,700,000
Tổng thu: 1,700,000 × 10 = 17,000,000
Người A nhận: 1,700,000 × (10-1) = 15,300,000
Dư kỳ 1: 17,000,000 - 15,300,000 = 1,700,000

🔵 Kỳ 2 (Người B hốt, bỏ 200k)
H = {A} (A đã hốt)
U = {B, C, D, E, F, G, H, I, J} (9 người)

A trả: 2,000,000 (đầy đủ)
9 người U trả: 2,000,000 - 200,000 = 1,800,000
Tổng thu: 2,000,000 + (1,800,000 × 9) = 18,200,000
Người B nhận: 1,800,000 × (9-1) = 14,400,000
Dư kỳ 2: 18,200,000 - 14,400,000 = 3,800,000

🔵 Kỳ 3 (Người C hốt, bỏ 100k)
H = {A, B}
U = {C, D, E, F, G, H, I, J} (8 người)

A, B trả: 2,000,000 mỗi người = 4,000,000
8 người U trả: 2,000,000 - 100,000 = 1,900,000
Tổng thu: 4,000,000 + (1,900,000 × 8) = 19,200,000
Người C nhận: 1,900,000 × (8-1) = 13,300,000
Dư kỳ 3: 19,200,000 - 13,300,000 = 5,900,000

📊 Tổng tiền dư sau 3 kỳ:
1,700,000 + 3,800,000 + 5,900,000 = 11,400,000

Lưu ý:
- Người hốt sớm nhận ít hơn nhưng được hưởng giảm giá lâu hơn
- Người hốt muộn nhận nhiều hơn nhưng phải trả đầy đủ nhiều kỳ hơn
- Tiền dư tích luỹ là lợi nhuận của dây hụi
```

### Trong ứng dụng

1. Tạo dây hụi với type = `HuiType.interest`
2. App tự động sinh `totalPeriods` kỳ góp
3. Mỗi kỳ khi đã góp:
   - Đánh dấu đã góp
   - Nhập số tiền thực góp
   - **Nhập tên người hốt**
   - **Nhập tiền bỏ (VNĐ)** - số tiền người hốt chấp nhận bỏ ra
   - App tự động tính và hiển thị:
     - Số người đã hốt / chưa hốt
     - Thanh toán giảm giá
     - Tổng thu kỳ này
     - Số tiền người hốt nhận = `discounted × (|U| - 1)`
     - Tiền dư kỳ này
4. Báo cáo hiển thị tổng tiền dư tích luỹ (cumulative surplus)

## 3. Sinh Kỳ Góp Tự Động

Khi tạo dây hụi mới, app tự động sinh các kỳ góp dựa trên:

```dart
for (int i = 1; i <= totalPeriods; i++) {
  DateTime dueDate = calculateDueDate(startDate, frequency, i);
  createContribution(
    periodNumber: i,
    dueDate: dueDate,
    isPaid: false
  );
}

DateTime calculateDueDate(DateTime start, Frequency freq, int period) {
  switch (freq) {
    case daily:
      return start.add(Duration(days: period));
    case weekly:
      return start.add(Duration(days: period * 7));
    case monthly:
      return DateTime(start.year, start.month + period, start.day);
  }
}
```

## 4. Theo Dõi Kỳ Trễ Hạn

```dart
bool isOverdue(Contribution c) {
  return !c.isPaid && c.dueDate.isBefore(DateTime.now());
}

List<Contribution> getOverdueContributions(List<Contribution> all) {
  return all.where((c) => isOverdue(c)).toList();
}
```

## 5. Tính Tiến Độ

```dart
double calculateProgress(List<Contribution> contributions) {
  int total = contributions.length;
  int paid = contributions.where((c) => c.isPaid).length;
  return (paid / total) * 100;
}
```

## 6. Dự Báo Ngày Kết Thúc

```dart
DateTime calculateProjectedEndDate(HuiGroup hui) {
  return calculateDueDate(
    hui.startDate, 
    hui.frequency, 
    hui.totalPeriods - 1
  );
}
```

## 7. Quy Tắc Validation

### Khi tạo dây hụi:
- Tên: Không được rỗng
- Số kỳ: > 0
- Số thành viên: > 0
- Mệnh giá: > 0
- Ngày bắt đầu: Bất kỳ (có thể trong quá khứ)

### Khi cập nhật kỳ góp:
- Số tiền thực góp: >= 0 (có thể khác mệnh giá)
- Tiền bỏ (hụi sống): >= 0, <= tổng góp
- Tên người hốt (hụi sống): Không rỗng nếu có người hốt

### Quy tắc đấu giá (hụi sống):
- Mỗi thành viên chỉ được hốt đúng 1 lần
- Kỳ cuối cùng: người còn lại tự động hốt với tiền bỏ = 0
- Tiền bỏ không được vượt quá tổng góp của kỳ

## 8. Xử Lý Edge Cases

### Thay đổi số kỳ sau khi tạo
- Không cho phép thay đổi `totalPeriods` sau khi đã tạo
- Nếu cần thay đổi, phải tạo dây mới

### Xóa dây hụi
- Cascade delete: Xóa dây sẽ tự động xóa tất cả contributions và winners
- Hiện confirm dialog trước khi xóa

### Góp không đúng số tiền
- Cho phép nhập số tiền thực góp khác mệnh giá
- Tính toán dựa trên số tiền thực tế

### Người hốt lần 2
- Với hụi sống, mỗi người chỉ được hốt 1 lần
- App nên theo dõi danh sách người đã hốt
- Cảnh báo nếu nhập tên người đã hốt trước đó

### Kỳ cuối cùng
- Với hụi sống, kỳ cuối tự động tiền bỏ = 0
- Người cuối nhận đủ tổng góp

## 9. Báo Cáo & Analytics

### Dashboard
- Tổng số dây hụi
- Tổng đã góp (tất cả dây)
- Tổng còn phải góp
- Số kỳ trễ hạn

### Chi tiết dây hụi
- Tiến độ %
- Tổng đã góp / còn phải góp (của dây này)
- Kỳ trễ hạn
- Danh sách tất cả các kỳ

### Báo cáo
- Biểu đồ dòng tiền theo kỳ
- Chi tiết từng kỳ (đã góp/chưa góp)
- Dự báo ngày kết thúc
- Danh sách kỳ trễ hạn

## 10. Luồng Người Dùng

### Tạo dây hụi mới
1. Nhập thông tin cơ bản
2. Chọn loại hụi (chết/sống)
3. Chọn tần suất và ngày bắt đầu
4. Lưu → App tự sinh các kỳ góp

### Đóng một kỳ
1. Vào chi tiết dây hụi
2. Chọn kỳ cần đóng
3. Đánh dấu "Đã góp"
4. Nhập số tiền (nếu khác mệnh giá)
5. [Nếu hụi sống] Nhập người hốt và lãi
6. Lưu

### Xem báo cáo
1. Vào chi tiết dây hụi
2. Tab "Báo cáo"
3. Xem tổng quan, biểu đồ, chi tiết

### Theo dõi kỳ trễ
1. Dashboard hiển thị tổng kỳ trễ
2. Chi tiết dây hiển thị badge nếu có kỳ trễ
3. Báo cáo hiển thị danh sách chi tiết

## 11. Tính Năng Mở Rộng (Future)

- Thông báo kỳ sắp đến hạn
- Export báo cáo PDF/Excel
- Quản lý nhiều người trong dây
- Sync giữa các thiết bị
- Chia sẻ thông tin dây hụi
- Lịch sử thay đổi
