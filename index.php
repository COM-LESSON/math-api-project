<?php
// Math API - 통합된 메인 엔드포인트
// 충돌 해결: Backend API를 기본으로 하고 Frontend 정보 추가

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Frontend에서 직접 접근한 경우 API 대신 HTML 페이지로 리다이렉트
if (!isset($_GET['CMD']) && !isset($_POST['CMD'])) {
    // GET 요청이고 CMD 파라미터가 없으면 HTML 인터페이스로 리다이렉트
    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
    if (strpos($accept, 'text/html') !== false) {
        header('Location: /index.html');
        exit;
    }
}

// Backend API 로직 실행
require_once 'backend/api.php';
?>
