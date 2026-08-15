<?PHP
/* Copyright 2026, shxtmaker */
/* AJAX endpoint: returns real-time logical CPU frequency as JSON */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');

$compact = isset($_GET['compact']) && $_GET['compact'] === '1';
$cores_by_id = [];
$expected_cpu_ids = [];
$model = '';
$base_freq = 0;
$max_freq = 0;

// Read /proc/cpuinfo once and keep each frequency bound to its processor block.
$cpuinfo = @file_get_contents('/proc/cpuinfo');
if ($cpuinfo) {
    if (!$compact) {
        // Extract model name and its optional base frequency.
        if (preg_match('/^model name\s*:\s*(.+)$/m', $cpuinfo, $m)) {
            $model = trim($m[1]);
        }
        if (preg_match('/@\s*([\d.]+)\s*GHz/i', $model, $b)) {
            $base_freq = floatval($b[1]) * 1000;
        }
    }

    foreach (preg_split('/\R\s*\R/', trim($cpuinfo)) as $block) {
        if (!preg_match('/^processor\s*:\s*(\d+)/m', $block, $processor_match)) continue;

        $cpu_id = intval($processor_match[1]);
        $expected_cpu_ids[$cpu_id] = true;
        if (!preg_match('/^cpu MHz\s*:\s*([\d.]+)/m', $block, $frequency_match)) continue;

        $cores_by_id[$cpu_id] = [
            'cpu'  => $cpu_id,
            'core' => $cpu_id,
            'mhz'  => round(floatval($frequency_match[1]), 2)
        ];
    }
}

// Only scan sysfs when /proc/cpuinfo omitted one or more frequency readings.
if (!$expected_cpu_ids || count($cores_by_id) < count($expected_cpu_ids)) {
    $freq_files = glob('/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq') ?: [];
    natsort($freq_files);
    foreach ($freq_files as $f) {
        if (!preg_match('/\/cpu(\d+)\/cpufreq\//', $f, $match)) continue;
        $cpu_id = intval($match[1]);
        if (isset($cores_by_id[$cpu_id])) continue;

        $val = @file_get_contents($f);
        if ($val !== false && is_numeric(trim($val))) {
            $cores_by_id[$cpu_id] = [
                'cpu'  => $cpu_id,
                'core' => $cpu_id,
                'mhz'  => round(intval(trim($val)) / 1000, 2)
            ];
        }
    }
}

ksort($cores_by_id, SORT_NUMERIC);
$cores = array_values($cores_by_id);

// Calculate statistics from successful readings only.
$frequencies = array_column($cores, 'mhz');
$core_count = count($cores);
$avg = $core_count > 0 ? round(array_sum($frequencies) / $core_count, 2) : null;
$response = $compact
    ? ['avg_mhz' => $avg, 'cores' => $cores]
    : [
        'timestamp'  => time(),
        'core_count' => $core_count,
        'avg_mhz'    => $avg,
        'cores'      => $cores
    ];

if (!$compact) {
    $max_file = '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq';
    $max_value = @file_get_contents($max_file);
    if ($max_value !== false && is_numeric(trim($max_value))) {
        $max_freq = intval(trim($max_value)) / 1000;
    }

    $gov_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor';
    $gov_value = @file_get_contents($gov_file);
    $governor = $gov_value === false ? '' : trim($gov_value);

    $response += [
        'model'     => $model,
        'min_mhz'   => $core_count > 0 ? round(min($frequencies), 2) : null,
        'max_mhz'   => $core_count > 0 ? round(max($frequencies), 2) : null,
        'base_mhz'  => $base_freq,
        'boost_mhz' => $max_freq,
        'governor'  => $governor
    ];
}

echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
