#!/bin/bash
# Math API 고급 모니터링 스크립트
# DevOps Engineer 작성

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear
echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║      Math API 시스템 모니터            ║${NC}"
echo -e "${PURPLE}║         DevOps Engineer                ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"

# 1. 시스템 리소스 모니터링
echo -e "\n${BLUE}📊 시스템 리소스 현황${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# CPU 사용률
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo -e "🖥 CPU 사용률: ${CPU_USAGE}%"

# 메모리 사용률
MEMORY_INFO=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2 }')
echo -e "💾 메모리 사용률: ${MEMORY_INFO}%"

# 디스크 사용률
DISK_USAGE=$(df -h /var | awk 'NR==2 {print $5}')
echo -e "💿 디스크 사용률: $DISK_USAGE"

# 2. 네트워크 연결 상태
echo -e "\n${BLUE}🌐 네트워크 연결 상태${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
netstat -tuln | grep -E ":80|:22|:443" | while read line; do
    echo "🔗 $line"
done

# 3. 서비스 상태 점검
echo -e "\n${BLUE}🔧 서비스 상태 점검${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_service() {
    local service=$1
    local display_name=$2
    if sudo service $service status >/dev/null 2>&1; then
        echo -e "✅ $display_name: ${GREEN}실행 중${NC}"
    else
        echo -e "❌ $display_name: ${RED}정지됨${NC}"
    fi
}

check_service "nginx" "Nginx 웹서버"
check_service "php8.3-fpm" "PHP-FPM"

# 4. API 엔드포인트 테스트
echo -e "\n${BLUE}🚀 API 엔드포인트 테스트${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_endpoint() {
    local endpoint=$1
    local description=$2
    echo -e "\n📡 테스트: $description"
    RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/api_test.json "$endpoint")
    HTTP_CODE="${RESPONSE: -3}"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "   상태: ${GREEN}성공 (HTTP $HTTP_CODE)${NC}"
        CONTENT=$(cat /tmp/api_test.json | head -c 100)
        echo -e "   응답: ${CONTENT}..."
    else
        echo -e "   상태: ${RED}실패 (HTTP $HTTP_CODE)${NC}"
    fi
}

test_endpoint "http://localhost/?CMD=HELLO" "HELLO 명령"
test_endpoint "http://localhost/?CMD=STATUS" "STATUS 명령"
test_endpoint "http://localhost/?CMD=INFO" "INFO 명령"
test_endpoint "http://localhost/" "기본 엔드포인트"

# 5. 로그 파일 분석
echo -e "\n${BLUE}📋 로그 분석 (최근 10개 항목)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n📄 Nginx 접근 로그:"
if [ -f "/var/log/nginx/math-api-project-access.log" ]; then
    sudo tail -5 /var/log/nginx/math-api-project-access.log | while read line; do
        echo "   📄 $line"
    done
else
    echo "   ⚠️ 접근 로그 파일이 없습니다"
fi

echo -e "\n🚨 Nginx 에러 로그:"
if [ -f "/var/log/nginx/math-api-project-error.log" ]; then
    if [ -s "/var/log/nginx/math-api-project-error.log" ]; then
        sudo tail -5 /var/log/nginx/math-api-project-error.log | while read line; do
            echo "   ❗ $line"
        done
    else
        echo -e "   ${GREEN}✅ 에러 로그가 없습니다 (정상)${NC}"
    fi
else
    echo "   ⚠️ 에러 로그 파일이 없습니다"
fi

# 6. 프로세스 모니터링
echo -e "\n${BLUE}⚙️ 관련 프로세스 현황${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ps aux | grep -E "(nginx|php)" | grep -v grep | while read line; do
    echo "🔄 $line"
done

# 7. 포트 사용 현황
echo -e "\n${BLUE}🔌 포트 사용 현황${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ss -tuln | grep -E ":80|:22|:443|:8001" | while read line; do
    echo "🔗 $line"
done

# 8. 최종 상태 요약
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            모니터링 완료                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "📊 점검 시간: $(date)"
echo -e "💻 시스템 가동 시간: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo -e "👥 현재 접속 사용자: $(who | wc -l)명"

# 알림 기능 (오류 발생 시)
if [ "$HTTP_CODE" != "200" ]; then
    echo -e "\n${RED}⚠️ 경고: API 응답에 문제가 있습니다!${NC}"
    echo -e "${RED}   즉시 확인이 필요합니다.${NC}"
fi

echo -e "\n${BLUE}🔄 실시간 모니터링을 원한다면 'watch ./monitor.sh'를 실행하세요${NC}"