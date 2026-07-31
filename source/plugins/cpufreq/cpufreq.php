<?PHP
/* Copyright 2026, CPU Frequency Plugin for UNRAID */
/* AJAX endpoint: returns real-time per-core CPU frequency as JSON */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');

$cores = [];
$model = '';
$base_freq = 0;
$max_freq = 0;

// Read /proc/cpuinfo for per-core MHz and CPU model
$cpuinfo = @file_get_contents('/proc/cpuinfo');
if ($cpuinfo) {
    // Extract model name
    if (preg_match('/^model name\s*:\s*(.+)$/m', $cpuinfo, $m)) {
        $model = trim($m[1]);
    }
    // Extract base frequency from model name (e.g. "@ 3.60GHz")
    if (preg_match('/@\s*([\d.]+)\s*GHz/i', $model, $b)) {
        $base_freq = floatval($b[1]) * 1000;
    }
    // Extract per-core current frequency
    preg_match_all('/^processor\s*:\s*(\d+).*?^cpu MHz\s*:\s*([\d.]+)/ms', $cpuinfo, $matches, PREG_SET_ORDER);
    foreach ($matches as $match) {
        $cores[] = [
            'core' => intval($match[1]),
            'mhz'  => round(floatval($match[2]), 2)
        ];
    }
}

// Fallback: sysfs cpufreq interface (kHz values)
if (empty($cores)) {
    $freq_files = glob('/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq');
    if ($freq_files) {
        natsort($freq_files);
        $i = 0;
        foreach ($freq_files as $f) {
            $val = @file_get_contents($f);
            if ($val !== false) {
                $cores[] = [
                    'core' => $i,
                    'mhz'  => round(intval(trim($val)) / 1000, 2)
                ];
            }
            $i++;
        }
    }
}

// Read max frequency from sysfs if available
$max_file = '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq';
if (file_exists($max_file)) {
    $val = @file_get_contents($max_file);
    if ($val !== false) {
        $max_freq = intval(trim($val)) / 1000; // kHz -> MHz
    }
}

// Calculate statistics
$frequencies = array_column($cores, 'mhz');
$core_count = count($cores);
$avg = $core_count > 0 ? round(array_sum($frequencies) / $core_count, 2) : 0;
$min = $core_count > 0 ? round(min($frequencies), 2) : 0;
$max = $core_count > 0 ? round(max($frequencies), 2) : 0;

// Determine scaling governor
$governor = '';
$gov_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor';
if (file_exists($gov_file)) {
    $governor = trim(@file_get_contents($gov_file));
}

echo json_encode([
    'timestamp'  => time(),
    'model'      => $model,
    'core_count' => $core_count,
    'avg_mhz'    => $avg,
    'min_mhz'    => $min,
    'max_mhz'    => $max,
    'base_mhz'   => $base_freq,
    'boost_mhz'  => $max_freq,
    'governor'   => $governor,
    'cores'      => $cores
], JSON_UNESCAPED_UNICODE);
