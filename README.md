# BotBongDa

Bot Telegram riêng tư bằng tiếng Việt: tra cứu trận mới, lưu dự đoán trước trận,
chấm 1X2/Tài-Xỉu chính xác theo line, giữ nguồn và tích lũy bài học có điều kiện.
GitHub Actions chạy lịch; một dịch vụ web thường trực nhận Telegram và giữ SQLite.
Không có thư viện Python bên ngoài ở runtime; Python 3.12+.

**Trạng thái:** mã nguồn và kiểm thử offline đã có. Chưa cấu hình token, chưa triển khai,
chưa gọi OpenAI/Telegram thật. Không tuyên bố dự đoán đã được kiểm định hoặc bot đang online.

## Bạn sẽ dùng thế nào?

- `/homnay`: báo cáo dự đoán đã lưu, có thời điểm để biết đã cũ hay chưa.
- `/ketqua`: đánh giá sau trận.
- `/kinhnghiem`: bài học đề xuất/đang dùng và ID chứng cứ.
- `/thongke`: số trận theo thị trường, thắng/nửa/hoàn/thua; chỉ có odds mới tính kết quả giá.
- `/trangthai`: hàng đợi, lỗi và giới hạn API.
- `/dudoan`, `/danhgia`: xếp tác vụ thủ công, tối đa một đợt mỗi loại/ngày.
- Nhắn tên trận/câu hỏi để tra cứu và hỏi nối tiếp. Lịch sử 20 tin gần nhất được đưa vào ngữ cảnh.

Mặc định báo cáo theo lịch được lưu **âm thầm**; `NOTIFY_REPORTS=true` mới chủ động gửi Telegram.
Lệnh chat luôn trả lời. Hỏi trong chat chưa tự trở thành một dự đoán đăng ký để chấm thành tích.

## Những gì không thể tự tạo thay bạn

1. Token Telegram do bạn tạo với @BotFather; gửi `/start` cho bot mới.
2. API key OpenAI có quyền dùng mô hình và web search; API tính phí riêng với ChatGPT Plus.
3. Tài khoản dịch vụ web có HTTPS và ổ đĩa bền vững. Bạn duyệt chi phí trước khi tạo.
4. Quyền đưa mã lên repository và cấu hình GitHub Secrets.

Không gửi token/API key vào chat, commit, ảnh chụp hoặc file công khai.

## Cách triển khai nhanh: Render + GitHub Actions

`render.yaml` là bản cấu hình gợi ý **dịch vụ trả phí** có persistent disk, không tự mua hoặc triển khai.
Bạn có thể dùng VPS/Docker ở phần dưới nếu đã có máy chủ.

1. Đưa toàn bộ mã (gồm `.github/workflows`) lên repository, nhánh mặc định `main`.
   Khuyến nghị repository private. Nếu upload qua giao diện web, kiểm tra thư mục ẩn `.github` có đủ.
2. Trong Render, tạo Blueprint từ repository, đọc giá dịch vụ/disk rồi mới xác nhận.
   Chạy đúng **một instance**, một process, với disk `/data`; không dùng filesystem tạm thời.
3. Điền biến môi trường `TELEGRAM_BOT_TOKEN`, `TELEGRAM_USER_ID`, `TELEGRAM_CHAT_ID`,
   `OPENAI_API_KEY`, `BOT_BASE_URL` là URL HTTPS Render cấp. Render tạo `JOBS_SECRET` và
   `WEBHOOK_SECRET` khác nhau; giữ kín hai giá trị này. `OPENAI_MODEL` mặc định `gpt-6-astra`,
   đổi nếu tài khoản có mô hình khác hỗ trợ Responses API + web_search + structured outputs.
4. Đợi `/healthz` trả `{"ok":true}`. Đây chỉ xác nhận web/DB hoạt động, không xác nhận API.
5. GitHub repository → Settings → Secrets and variables → Actions:
   - Secrets `BOT_BASE_URL`: URL dịch vụ HTTPS, không có dấu `/` cuối.
   - Secrets `JOBS_SECRET`: đúng giá trị ở dịch vụ.
   - Variable `BOT_SCHEDULE_ENABLED`: `true` khi đã sẵn sàng chạy lịch và chấp nhận phí API.
6. GitHub → Actions → **Football jobs** → Run workflow → operation **configure**.
   Bước này đăng ký webhook và danh sách lệnh Telegram; không xóa tin chưa nhận.
7. Mở bot Telegram, gửi `/start`, `/trangthai`. Chọn operation **forecast** để thử một đợt thật.
   Workflow chờ trạng thái hoàn tất thật, không coi HTTP 202 là tác vụ đã xong.
8. Gửi `/homnay` để xem. Khi đủ thời gian, chạy **review** và gửi `/ketqua`.

Lịch Actions mặc định: **15:17 dự đoán**, **08:17 đánh giá**, giờ Việt Nam.
Actions có thể trễ hoặc bỏ lượt; không dùng để bảo đảm cập nhật đội hình đúng sát giờ.
Repo public có thể bị GitHub tắt lịch sau thời gian không hoạt động; kiểm tra Actions định kỳ.
Hai lịch trong ChatGPT hiện có là hệ thống riêng, không được bot tự tắt hoặc đồng bộ.

### Lấy ID Telegram

Dùng ID số của chính bạn, không phải `@username` hay tên hiển thị. Trong chat riêng với bot,
chat ID thường bằng user ID. Nếu bạn đã biết ID thì nhập trực tiếp. Nếu chưa biết, sau khi gửi
`/start` và trước khi cấu hình webhook, có thể gọi `getUpdates` bằng script cục bộ với token từ
biến môi trường; không dán URL chứa token lên trình duyệt chung/issue. Nếu webhook đang bật,
`getUpdates` không hoạt động; không tự xóa webhook bot đang dùng cho ứng dụng khác.
Xem [hướng dẫn cấu hình](docs/operations.md) và script `scripts/get_my_id.py`.

## VPS / Docker Compose

1. Cài Docker/Compose từ nguồn chính thức trên VPS.
2. Chạy `python scripts/create_env.py` trên máy riêng để tạo `.env` (không ghi log khóa).
3. Chạy `docker compose up -d --build`.
4. Đặt reverse proxy HTTPS (Caddy/nginx hoặc nền tảng của bạn) chuyển về `127.0.0.1:8080`.
   DNS, domain và chứng chỉ thuộc tài khoản của bạn; `BOT_BASE_URL` phải khớp URL public đó.
5. Cấu hình hai GitHub Secrets và chạy **configure** như trên. Chỉ mở cổng HTTPS public;
   Compose mặc định không công khai cổng HTTP 8080 ra Internet.

Không cần GitHub Actions để bot chat: webhook + server vẫn trả lời. Nếu không dùng Actions,
hãy dùng cron riêng gọi `/jobs/forecast` và `/jobs/review` với Bearer secret.

## Dữ liệu và cách “rút kinh nghiệm”

- Lịch 24h được đọc trực tiếp và đưa vào nghiên cứu web để đối chiếu; không coi HTML là chỉ thị.
- Mỗi đợt tối đa 3 trận khác nhau, chỉ trận trong 24 giờ tới, còn ít nhất 10 phút trước bóng lăn.
- Hai giai đoạn: nghiên cứu có web search/citations → JSON strict → kiểm tra chương trình → lưu.
- Mỗi ứng viên cần ít nhất 2 tên miền độc lập được API trích dẫn; URL bịa không được chấp nhận.
  Đây **không** bảo đảm nguồn đúng, độc lập về biên tập hoặc dữ liệu mới. Kết quả do AI trích vẫn
  có thể sai; cần kiểm tra nguồn khi quan trọng. Chưa tích hợp nguồn kết quả có hợp đồng/API chính thức.
- Dự đoán gốc không được UPDATE/DELETE; mỗi trận chỉ có một dự đoán đăng ký. Nhận định chat sau đó
  không thay thế bản gốc. Lưu kết quả riêng, 90 phút + bù giờ, không hiệp phụ/penalty.
- Line tham chiếu/thiếu odds chỉ chấm hướng tham khảo; không gọi là lợi thế hay tính lợi nhuận.
- Lưu toàn bộ nghiên cứu/nguồn của mỗi dự đoán và mỗi lần xác minh kết quả trong SQLite.
- Bài học dưới 3 hồ sơ có kết quả chỉ là đề xuất. Từ 3 hồ sơ được đưa vào ngữ cảnh có nhãn rõ,
  không phải bằng chứng thống kê hay tự điều chỉnh trọng số. Không tự sửa mã/chạy lệnh do AI tạo.
- Mô hình không tự huấn luyện. Muốn chứng minh tiến bộ cần tập đánh giá tương lai độc lập.
- Bot có bộ phương pháp riêng ở `docs/methodology.md` và kho bài học SQLite. **Chưa có kết nối tự
  cập nhật plugin hoặc Library ChatGPT.** Không dùng session/cookie ChatGPT làm API không chính thức.

## Chi phí và giới hạn

`MAX_API_CALLS_PER_DAY=30` là giới hạn **lượt yêu cầu** mỗi ngày Việt Nam, không phải giới hạn tiền.
Một lượt nghiên cứu có thể tìm nhiều lần; token và web search có phí. Đặt thêm budget/usage limit
ở tài khoản API. Không retry API ngầm khi lỗi để tránh phí ngoài dự kiến.
Mỗi đợt dự đoán thường 2 requests; đánh giá tối đa 3 trận × 2 requests và 1 request tổng hợp bài học.
Chat tra cứu dùng thêm requests. Mô hình/công cụ không có quyền, không đủ ngân sách hoặc API lỗi:
bot dừng bước đó và báo lỗi, không dùng trí nhớ để tạo dữ liệu thay thế.

## Kiểm thử

```bash
python -m unittest discover -s tests -v
python -m compileall -q bot scripts
```

Kiểm thử HTTP webhook qua server cục bộ, chống gửi trùng, phân quyền người dùng, giới hạn API nguyên tử,
bất biến dự đoán, không chấm nhầm trận/hiệp phụ, từ chối nguồn không có citation, phép tính toàn bộ line
chia tư trên nhiều tỷ số. Toàn bộ dùng API giả lập, không tiêu tiền hoặc gửi Telegram thật.
Docker và API live cần được smoke-test sau khi có môi trường/credentials.

## Khôi phục và vận hành

Đọc [docs/operations.md](docs/operations.md). SQLite disk là nguồn dữ liệu chính; không ghi dữ liệu
riêng tư vào repository. Chạy export chỉ ở repo private; bản export là dữ liệu riêng, không public.
Snapshot toàn bộ disk mới là backup đầy đủ. Giữ một process/instance để tránh nhận lại việc đang chạy.
