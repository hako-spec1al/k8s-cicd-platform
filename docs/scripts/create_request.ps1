# Tạo lưu lượng biến thiên: request bình thường xen kẽ request ngẫu nhiên
for i in {1..300}; do
  curl -s http://127.0.0.1:8000/health > /dev/null
  curl -s http://127.0.0.1:8000/metrics > /dev/null
  sleep 0.1
done