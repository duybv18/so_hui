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

## 2. Hụi Sống (Interest-based ROSCA)

### Đặc điểm
- Mỗi kỳ, người muốn hốt phải "ra giá" (đấu giá)
- Ai trả mức lãi cao hơn thì được hốt kỳ đó
- Số tiền nhận được = tổng góp - phần lãi
- Lãi được chia cho các thành viên còn lại
- Người hốt càng sớm thường chịu lãi cao hơn

### Công thức tính toán

```dart
// Tổng góp mỗi kỳ
totalContribution = contributionAmount × numMembers

// Tiền lãi
interestAmount = totalContribution × interestRate

// Người hốt nhận
amountReceived = totalContribution - interestAmount

// Lãi chia cho mỗi người còn lại
interestPerPerson = interestAmount / (numMembers - 1)

// Tổng lãi tích luỹ (cho dây)
accumulatedInterest = Σ(interestAmount) for all winners
```

### Ví dụ

```
Dây hụi: 10 người, mỗi kỳ góp 1 triệu
Tổng số kỳ: 10
Tần suất: Hàng tháng

Kỳ 1: 
- 10 người góp 1tr = 10tr tổng
- Người A hốt với lãi 5% (500k)
- A nhận: 10tr - 500k = 9.5tr
- 9 người còn lại mỗi người được chia: 500k / 9 ≈ 55.5k

Kỳ 2:
- 10 người góp 1tr = 10tr tổng
- Người B hốt với lãi 4% (400k)
- B nhận: 10tr - 400k = 9.6tr
- 9 người còn lại mỗi người được chia: 400k / 9 ≈ 44.4k

...

Kỳ cuối:
- Thường không có lãi hoặc lãi thấp
- Người cuối cùng nhận gần bằng tổng góp
```

### Trong ứng dụng

1. Tạo dây hụi với type = `HuiType.interest`
2. App tự động sinh `totalPeriods` kỳ góp
3. Mỗi kỳ khi đã góp:
   - Đánh dấu đã góp
   - Nhập số tiền thực góp
   - **Nhập tên người hốt**
   - **Nhập lãi suất (%)** 
   - App tự động tính và hiển thị:
     - Tổng góp
     - Tiền lãi
     - Số tiền người hốt nhận
4. Báo cáo hiển thị tổng lãi tích luỹ

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
- Lãi suất (hụi sống): 0-100%
- Tên người hốt (hụi sống): Không rỗng nếu có lãi

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

### Kỳ hốt không có lãi
- Với hụi sống, cho phép lãi = 0%
- Người hốt nhận đúng tổng góp

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
