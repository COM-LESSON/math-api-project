<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// 요청 메소드 처리
$request_method = $_SERVER['REQUEST_METHOD'];
$input_data = array();

if ($request_method == 'GET') {
    $input_data = $_GET;
} elseif ($request_method == 'POST') {
    $content_type = $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($content_type, 'application/json') !== false) {
        $json_input = json_decode(file_get_contents('php://input'), true);
        $input_data = $json_input ?? array();
    } else {
        $input_data = $_POST;
    }
}

// 기본 응답 구조
$response = array(
    'timestamp' => date('Y-m-d H:i:s'),
    'request_data' => $input_data,
    'response' => null,
    'status' => 'SUCCESS',
    'version' => '2.0.0-sprint1',
    'developer' => 'Backend Developer'
);

// CMD 파라미터 검증 및 처리
if (!isset($input_data['CMD']) || empty($input_data['CMD'])) {
    $response['response'] = 'ERROR: CMD parameter is required';
    $response['status'] = 'ERROR';
    $response['available_commands'] = ['HELLO', 'STATUS', 'INFO'];
} else {
    $cmd = strtoupper(trim($input_data['CMD']));
    
    switch ($cmd) {
        case 'HELLO':
            $response['response'] = array(
                'message' => 'Hello from Math API V2!',
                'sprint' => 'Sprint 1',
                'backend_status' => 'Backend API is ready',
                'greeting' => 'Welcome to collaborative development!'
            );
            break;
            
        case 'STATUS':
            $response['response'] = array(
                'api_status' => 'RUNNING',
                'server_time' => date('Y-m-d H:i:s'),
                'uptime' => 'Active',
                'backend_version' => '2.0.0',
                'database_status' => 'Connected',
                'cache_status' => 'Active'
            );
            break;
            
        case 'INFO':
            $response['response'] = array(
                'project_name' => 'Math API V2',
                'sprint' => 'Sprint 1 - Basic Structure',
                'team_size' => 4,
                'technologies' => ['PHP', 'JavaScript', 'HTML', 'CSS', 'Docker', 'GitHub']
            );
            break;
            
        default:
            $response['response'] = "ERROR: Unknown command '{$cmd}'";
            $response['status'] = 'ERROR';
            $response['available_commands'] = ['HELLO', 'STATUS', 'INFO'];
            break;
    }
}

// JSON 응답 출력
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>