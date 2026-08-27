package com.yulo.os;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.yulo.os.databinding.ActivityMainBinding;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private ProotManager prootManager;
    private boolean isRunning = false;

    private static final int PERMISSION_REQUEST = 1001;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        prootManager = new ProotManager(this);

        setupViews();
        checkPermissions();
        requestBatteryOptimization();
    }

    private void setupViews() {
        binding.btnStart.setOnClickListener(v -> startYuloOS());
        binding.btnStop.setOnClickListener(v -> stopYuloOS());
        binding.btnSettings.setOnClickListener(v -> openSettings());
        binding.btnHelp.setOnClickListener(v -> showHelp());
        binding.btnDownload.setOnClickListener(v -> downloadRootfs());

        updateUI();
    }

    private void checkPermissions() {
        String[] permissions = {
            Manifest.permission.INTERNET,
            Manifest.permission.ACCESS_NETWORK_STATE,
            Manifest.permission.WAKE_LOCK,
            Manifest.permission.VIBRATE
        };

        boolean allGranted = true;
        for (String perm : permissions) {
            if (ContextCompat.checkSelfPermission(this, perm) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }

        if (!allGranted) {
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST);
        }
    }

    private void requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent();
            String packageName = getPackageName();
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.parse("package:" + packageName));
                startActivity(intent);
            }
        }
    }

    private void downloadRootfs() {
        binding.tvStatus.setText("正在下载 yulo OS ARM64 rootfs...");
        binding.progressBar.setVisibility(View.VISIBLE);
        binding.btnDownload.setEnabled(false);

        prootManager.downloadRootfs(new ProotManager.DownloadCallback() {
            @Override
            public void onProgress(int percent) {
                runOnUiThread(() -> {
                    binding.progressBar.setProgress(percent);
                    binding.tvStatus.setText("下载中... " + percent + "%");
                });
            }

            @Override
            public void onComplete() {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    binding.btnDownload.setEnabled(true);
                    binding.tvStatus.setText("下载完成！可以启动系统了");
                    Toast.makeText(MainActivity.this, "yulo OS 下载完成", Toast.LENGTH_SHORT).show();
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    binding.btnDownload.setEnabled(true);
                    binding.tvStatus.setText("下载失败: " + message);
                    Toast.makeText(MainActivity.this, "下载失败: " + message, Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    private void startYuloOS() {
        if (!prootManager.isRootfsDownloaded()) {
            Toast.makeText(this, "请先下载 yulo OS", Toast.LENGTH_SHORT).show();
            return;
        }

        binding.tvStatus.setText("正在启动 yulo OS...");
        binding.btnStart.setEnabled(false);

        Intent serviceIntent = new Intent(this, YuloService.class);
        serviceIntent.setAction(YuloService.ACTION_START);
        ContextCompat.startForegroundService(this, serviceIntent);

        prootManager.startYuloOS(new ProotManager.StartCallback() {
            @Override
            public void onStarted() {
                runOnUiThread(() -> {
                    isRunning = true;
                    updateUI();
                    binding.tvStatus.setText("yulo OS 已启动！连接 VNC...");
                    startVncActivity();
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    binding.btnStart.setEnabled(true);
                    binding.tvStatus.setText("启动失败: " + message);
                    Toast.makeText(MainActivity.this, "启动失败: " + message, Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    private void stopYuloOS() {
        binding.tvStatus.setText("正在停止 yulo OS...");
        prootManager.stopYuloOS();

        Intent serviceIntent = new Intent(this, YuloService.class);
        serviceIntent.setAction(YuloService.ACTION_STOP);
        startService(serviceIntent);

        isRunning = false;
        updateUI();
        binding.tvStatus.setText("yulo OS 已停止");
    }

    private void startVncActivity() {
        Intent intent = new Intent(this, VncActivity.class);
        startActivity(intent);
    }

    private void openSettings() {
        Intent intent = new Intent(this, SettingsActivity.class);
        startActivity(intent);
    }

    private void showHelp() {
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("yulo OS 触摸操控指南")
                .setMessage(
                    "【基础操作】\n" +
                    "• 单指点击 = 鼠标左键\n" +
                    "• 单指双击 = 双击\n" +
                    "• 单指长按 = 鼠标右键\n" +
                    "• 单指拖动 = 拖动窗口/选择文本\n\n" +
                    "【滚动操作】\n" +
                    "• 双指上下滑动 = 滚轮滚动\n" +
                    "• 双指左右滑动 = 水平滚动\n\n" +
                    "【缩放手势】\n" +
                    "• 双指捏合 = 缩小\n" +
                    "• 双指张开 = 放大\n\n" +
                    "【多任务】\n" +
                    "• 三指上滑 = 活动概览\n" +
                    "• 三指左右滑 = 切换工作区\n" +
                    "• 三指下滑 = 显示桌面\n\n" +
                    "【默认账号】\n" +
                    "用户名: yulo\n" +
                    "密码: yulo"
                )
                .setPositiveButton("知道了", null)
                .show();
    }

    private void updateUI() {
        if (isRunning) {
            binding.btnStart.setVisibility(View.GONE);
            binding.btnStop.setVisibility(View.VISIBLE);
            binding.tvStatus.setText("yulo OS 运行中");
        } else {
            binding.btnStart.setVisibility(View.VISIBLE);
            binding.btnStop.setVisibility(View.GONE);
            binding.tvStatus.setText("yulo OS 未运行");
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (prootManager != null) {
            prootManager.cleanup();
        }
    }
}
