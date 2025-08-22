<?php
// Frontend에서 생성한 메인 페이지 (Backend와 충돌 예정!)
header('Content-Type: application/json; charset=utf-8');

$response = array(
    'message' => 'Hello from Frontend API',
    'version' => '2.0.0-frontend',
    'developer' => 'Frontend Developer',
    'status' => 'Frontend Ready',
    'timestamp' => date('Y-m-d H:i:s'),
    'note' => 'This will conflict with backend index.php!'
);

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>