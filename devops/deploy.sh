#!/bin/bash
# Math API 고급 배포 스크립트
# DevOps Engineer 작성

set -e # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Math API 배포 시작                 ║${NC}"
echo -e "${BLUE}║     DevOps Engineer                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# 환경 변수 설정
DEPLOY_DIR="/var/www/math-api"
BACKUP_DIR="/var/backups/math-api"
NGINX_CONF="devops/nginx-mathapi.conf"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# 1. 환경 점검
log_info "시스템 환경 점검 중..."
if [ ! -d "$DEPLOY_DIR" ]; then
    log_error "배포 디렉토리가 존재하지 않습니다: $DEPLOY_DIR"
    exit 1
fi

# 디스크 공간 확인
DISK_USAGE=$(df /var | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    log_warning "디스크 사용량이 높습니다: ${DISK_USAGE}%"
fi

log_success "환경 점검 완료"

# 2. 백업 생성
log_info "기존 파일 백업 생성 중..."
BACKUP_PATH="${BACKUP_DIR}-${TIMESTAMP}"
sudo mkdir -p "$BACKUP_PATH"

if [ "$(ls -A $DEPLOY_DIR 2>/dev/null)" ]; then
    sudo cp -r $DEPLOY_DIR/* "$BACKUP_PATH/"
    log_success "백업 생성 완료: $BACKUP_PATH"
else
    log_warning "백업할 파일이 없습니다"
fi

# 3. 서비스 상태 확인
log_info "서비스 상태 확인 중..."

# Nginx 상태 확인
if ! sudo service nginx status >/dev/null 2>&1; then
    log_warning "Nginx가 실행되지 않습니다. 시작합니다..."
    sudo service nginx start
fi

# PHP-FPM 상태 확인
if ! sudo service php8.3-fpm status >/dev/null 2>&1; then
    log_warning "PHP-FPM이 실행되지 않습니다. 시작합니다..."
    sudo service php8.3-fpm start
fi

log_success "서비스 상태 확인 완료"

# 4. 코드 배포
log_info "애플리케이션 코드 배포 중..."

# 백엔드 파일 배포
if [ -f "backend/api.php" ]; then
    sudo cp backend/api.php "$DEPLOY_DIR/"
    log_success "Backend API 배포 완료"
fi

if [ -f "index.php" ]; then
    sudo cp index.php "$DEPLOY_DIR/"
    log_success "메인 엔드포인트 배포 완료"
fi

# 프론트엔드 파일 배포
if [ -f "frontend/index.html" ]; then
    sudo cp frontend/index.html "$DEPLOY_DIR/"
    log_success "Frontend Interface 배포 완료"
fi

# 권한 설정
sudo chown -R www-data:www-data "$DEPLOY_DIR"
sudo chmod -R 755 "$DEPLOY_DIR"
sudo chmod 644 "$DEPLOY_DIR"/*.php "$DEPLOY_DIR"/*.html 2>/dev/null || true

# 5. Nginx 설정 업데이트
log_info "Nginx 설정 업데이트 중..."
if [ -f "$NGINX_CONF" ]; then
    sudo cp "$NGINX_CONF" /etc/nginx/sites-available/math-api
    sudo nginx -t
    if [ $? -eq 0 ]; then
        sudo service nginx reload
        log_success "Nginx 설정 업데이트 완료"
    else
        log_error "Nginx 설정 문법 오류!"
        exit 1
    fi
else
    log_warning "Nginx 설정 파일을 찾을 수 없습니다"
fi

# 6. 서비스 재시작 및 확인
log_info "서비스 최종 확인 중..."

# 서비스 재시작
sudo service php8.3-fpm restart
sudo service nginx restart

# 헬스 체크
sleep 3

# API 응답 테스트
log_info "API 응답 테스트 중..."
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/api_response.json http://localhost/?CMD=STATUS)
HTTP_CODE="${RESPONSE: -3}"

if [ "$HTTP_CODE" = "200" ]; then
    log_success "API 응답 테스트 통과 (HTTP 200)"
    cat /tmp/api_response.json | python3 -m json.tool 2>/dev/null || cat /tmp/api_response.json
else
    log_error "API 응답 테스트 실패 (HTTP $HTTP_CODE)"
fi

# 7. 배포 완료 리포트
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           배포 완료 리포트              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "📅 배포 시간: $(date)"
echo -e "📁 배포 경로: $DEPLOY_DIR"
echo -e "💾 백업 경로: $BACKUP_PATH"
echo -e "🌐 서비스 URL: http://localhost/"
echo -e "📊 API 상태: HTTP $HTTP_CODE"
echo -e "💽 디스크 사용률: ${DISK_USAGE}%"

# 8. 추가 정보
echo -e "\n${BLUE}📋 배포된 파일 목록:${NC}"
ls -la "$DEPLOY_DIR"

echo -e "\n${BLUE}🔧 서비스 상태:${NC}"
echo -e "Nginx: $(sudo service nginx status | grep -o 'Active: [^,]*' || echo 'Unknown')"
echo -e "PHP-FPM: $(sudo service php8.3-fpm status | grep -o 'Active: [^,]*' || echo 'Unknown')"

log_success "Math API 배포가 성공적으로 완료되었습니다!"