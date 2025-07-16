#!/bin/bash

# ============================================
# สคริปต์ตั้งค่าเวลาไทยใน Ubuntu
# ============================================

echo "🇹🇭 เริ่มต้นการตั้งค่าเวลาไทยใน Ubuntu"
echo "=========================================="

# ตรวจสอบสิทธิ์ sudo
if [[ $EUID -ne 0 ]]; then
   echo "❌ สคริปต์นี้ต้องใช้สิทธิ์ root หรือ sudo"
   echo "กรุณารันด้วยคำสั่ง: sudo bash $0"
   exit 1
fi

# ฟังก์ชันแสดงข้อมูลเวลาปัจจุบัน
show_current_time() {
    echo "📅 ข้อมูลเวลาปัจจุบัน:"
    echo "------------------------"
    timedatectl status
    echo ""
}

# แสดงเวลาปัจจุบันก่อนเปลี่ยน
echo "⏰ เวลาปัจจุบันก่อนเปลี่ยน:"
show_current_time

# ตั้งค่า timezone เป็นเวลาไทย
echo "🔧 กำลังตั้งค่า timezone เป็น Asia/Bangkok..."
timedatectl set-timezone Asia/Bangkok

# ตรวจสอบว่าตั้งค่าสำเร็จหรือไม่
if [ $? -eq 0 ]; then
    echo "✅ ตั้งค่า timezone สำเร็จ"
else
    echo "❌ เกิดข้อผิดพลาดในการตั้งค่า timezone"
    exit 1
fi

# เปิดใช้งาน NTP (Network Time Protocol)
echo "🌐 กำลังเปิดใช้งาน NTP..."
timedatectl set-ntp true

# ตรวจสอบสถานะ NTP
if [ $? -eq 0 ]; then
    echo "✅ เปิดใช้งาน NTP สำเร็จ"
else
    echo "❌ เกิดข้อผิดพลาดในการเปิดใช้งาน NTP"
fi

# อัพเดตเวลาจาก NTP server
echo "🔄 กำลังซิงค์เวลาจาก NTP server..."
systemctl restart systemd-timesyncd

# รอให้ซิงค์เสร็จ
sleep 3

# ตั้งค่า Hardware Clock
echo "⚙️ กำลังตั้งค่า Hardware Clock..."
hwclock --systohc

# แสดงเวลาหลังจากเปลี่ยน
echo ""
echo "🎉 เวลาหลังจากเปลี่ยนแล้ว:"
show_current_time

# ตรวจสอบว่าเป็นเวลาไทยหรือไม่
CURRENT_TZ=$(timedatectl show --property=Timezone --value)
if [ "$CURRENT_TZ" = "Asia/Bangkok" ]; then
    echo "✅ ตั้งค่าเวลาไทยสำเร็จ!"
else
    echo "❌ เกิดข้อผิดพลาด: timezone ยังไม่ใช่ Asia/Bangkok"
    echo "timezone ปัจจุบัน: $CURRENT_TZ"
fi

# ============================================
# ตั้งค่า MySQL timezone (ถ้ามี MySQL)
# ============================================

echo ""
echo "🗄️ ตรวจสอบและตั้งค่า MySQL timezone..."

# ตรวจสอบว่ามี MySQL หรือไม่
if command -v mysql &> /dev/null; then
    echo "พบ MySQL - กำลังตั้งค่า timezone..."
    
    # สร้างไฟล์ config สำหรับ MySQL
    cat > /etc/mysql/conf.d/timezone.cnf << EOF
[mysqld]
default-time-zone = '+07:00'
EOF

    echo "✅ สร้างไฟล์ config MySQL สำเร็จ"
    echo "📝 กรุณารีสตาร์ท MySQL ด้วยคำสั่ง: sudo systemctl restart mysql"
    
elif command -v mariadb &> /dev/null; then
    echo "พบ MariaDB - กำลังตั้งค่า timezone..."
    
    # สร้างไฟล์ config สำหรับ MariaDB
    cat > /etc/mysql/mariadb.conf.d/50-timezone.cnf << EOF
[mysqld]
default-time-zone = '+07:00'
EOF

    echo "✅ สร้างไฟล์ config MariaDB สำเร็จ"
    echo "📝 กรุณารีสตาร์ท MariaDB ด้วยคำสั่ง: sudo systemctl restart mariadb"
else
    echo "ℹ️ ไม่พบ MySQL/MariaDB ในระบบ"
fi

# ============================================
# ตั้งค่า Node.js timezone (ถ้ามี Node.js)
# ============================================

echo ""
echo "🟢 ตั้งค่า Node.js timezone..."

# ตรวจสอบว่ามี Node.js หรือไม่
if command -v node &> /dev/null; then
    echo "พบ Node.js - กำลังตั้งค่า timezone..."
    
    # เพิ่มการตั้งค่า timezone ใน .bashrc
    echo "" >> ~/.bashrc
    echo "# Thailand timezone for Node.js" >> ~/.bashrc
    echo "export TZ='Asia/Bangkok'" >> ~/.bashrc
    
    # เพิ่มใน .profile
    echo "" >> ~/.profile
    echo "# Thailand timezone for Node.js" >> ~/.profile
    echo "export TZ='Asia/Bangkok'" >> ~/.profile
    
    echo "✅ เพิ่มการตั้งค่า timezone ใน .bashrc และ .profile"
    echo "📝 กรุณา logout/login ใหม่ หรือรันคำสั่ง: source ~/.bashrc"
else
    echo "ℹ️ ไม่พบ Node.js ในระบบ"
fi

# ============================================
# สร้างไฟล์ตรวจสอบเวลา
# ============================================

echo ""
echo "📄 สร้างไฟล์ตรวจสอบเวลา..."

# สร้างสคริปต์ตรวจสอบเวลา
cat > /usr/local/bin/check-thai-time << 'EOF'
#!/bin/bash
echo "🇹🇭 ตรวจสอบเวลาไทย"
echo "===================="
echo "System Time: $(date)"
echo "UTC Time: $(date -u)"
echo "Timezone: $(timedatectl show --property=Timezone --value)"
echo "NTP Status: $(timedatectl show --property=NTP --value)"
echo "Time Sync: $(timedatectl show --property=NTPSynchronized --value)"
echo ""

# ตรวจสอบ MySQL timezone ถ้ามี
if command -v mysql &> /dev/null; then
    echo "MySQL timezone:"
    mysql -e "SELECT @@system_time_zone, @@session.time_zone;" 2>/dev/null || echo "ไม่สามารถเชื่อมต่อ MySQL"
fi

# ตรวจสอบ Node.js timezone ถ้ามี
if command -v node &> /dev/null; then
    echo "Node.js timezone:"
    node -e "console.log('TZ env:', process.env.TZ); console.log('Date:', new Date().toString());"
fi
EOF

# ให้สิทธิ์ execute
chmod +x /usr/local/bin/check-thai-time

echo "✅ สร้างไฟล์ตรวจสอบเวลา /usr/local/bin/check-thai-time"
echo "📝 ใช้คำสั่ง: check-thai-time เพื่อตรวจสอบเวลา"

# ============================================
# สร้าง cron job สำหรับซิงค์เวลา
# ============================================

echo ""
echo "⏰ ตั้งค่า cron job สำหรับซิงค์เวลา..."

# เพิ่ม cron job สำหรับซิงค์เวลาทุกวัน
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/sbin/ntpdate -s time.nist.gov") | crontab -

echo "✅ เพิ่ม cron job สำหรับซิงค์เวลาทุกวันเวลา 02:00"

# ============================================
# แสดงสรุปผลการตั้งค่า
# ============================================

echo ""
echo "🎉 สรุปผลการตั้งค่า"
echo "===================="
echo "✅ ตั้งค่า timezone เป็น Asia/Bangkok"
echo "✅ เปิดใช้งาน NTP"
echo "✅ ซิงค์ Hardware Clock"
echo "✅ สร้างไฟล์ตรวจสอบเวลา"
echo "✅ ตั้งค่า cron job สำหรับซิงค์เวลา"

# ตรวจสอบและแสดงไฟล์ config ที่สร้าง
if [ -f "/etc/mysql/conf.d/timezone.cnf" ] || [ -f "/etc/mysql/mariadb.conf.d/50-timezone.cnf" ]; then
    echo "✅ ตั้งค่า MySQL/MariaDB timezone"
fi

if grep -q "TZ='Asia/Bangkok'" ~/.bashrc; then
    echo "✅ ตั้งค่า Node.js timezone"
fi

echo ""
echo "📋 คำสั่งที่เป็นประโยชน์:"
echo "- ตรวจสอบเวลา: check-thai-time"
echo "- ตรวจสอบสถานะ: timedatectl status"
echo "- ซิงค์เวลาทันที: sudo systemctl restart systemd-timesyncd"
echo "- ตรวจสอบ NTP: timedatectl timesync-status"

echo ""
echo "🔄 กรุณารีสตาร์ทเซอร์วิส MySQL และ logout/login ใหม่"
echo "🇹🇭 ตั้งค่าเวลาไทยเสร็จสิ้น!"
