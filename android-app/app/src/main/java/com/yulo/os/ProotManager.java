package com.yulo.os;

import android.content.Context;
import android.os.Environment;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class ProotManager {

    private static final String TAG = "ProotManager";
    private static final String ROOTFS_URL = "https://github.com/yulozh/yulo/releases/download/v1.0/yulo-1.0-arm64-rootfs.tar.xz";
    private static final String ROOTFS_FILENAME = "yulo-arm64-rootfs.tar.xz";
    private static final String CONTAINER_NAME = "yulo";

    private Context context;
    private File filesDir;
    private Process currentProcess;

    public interface DownloadCallback {
        void onProgress(int percent);
        void onComplete();
        void onError(String message);
    }

    public interface StartCallback {
        void onStarted();
        void onError(String message);
    }

    public ProotManager(Context context) {
        this.context = context;
        this.filesDir = context.getFilesDir();
    }

    public boolean isRootfsDownloaded() {
        File rootfs = new File(filesDir, ROOTFS_FILENAME);
        return rootfs.exists() && rootfs.length() > 1000000; // > 1MB
    }

    public void downloadRootfs(DownloadCallback callback) {
        new Thread(() -> {
            try {
                URL url = new URL(ROOTFS_URL);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(30000);
                connection.setReadTimeout(300000);
                connection.connect();

                int responseCode = connection.getResponseCode();
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    callback.onError("HTTP error: " + responseCode);
                    return;
                }

                int contentLength = connection.getContentLength();
                InputStream inputStream = connection.getInputStream();
                File outputFile = new File(filesDir, ROOTFS_FILENAME);
                FileOutputStream outputStream = new FileOutputStream(outputFile);

                byte[] buffer = new byte[8192];
                int bytesRead;
                long totalBytesRead = 0;
                int lastPercent = -1;

                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                    totalBytesRead += bytesRead;

                    if (contentLength > 0) {
                        int percent = (int) ((totalBytesRead * 100) / contentLength);
                        if (percent != lastPercent) {
                            lastPercent = percent;
                            callback.onProgress(percent);
                        }
                    }
                }

                outputStream.flush();
                outputStream.close();
                inputStream.close();
                connection.disconnect();

                callback.onComplete();
            } catch (Exception e) {
                Log.e(TAG, "Download error", e);
                callback.onError(e.getMessage());
            }
        }).start();
    }

    public void startYuloOS(StartCallback callback) {
        new Thread(() -> {
            try {
                // 安装 proot 容器
                installContainer();

                // 启动 VNC 服务器和桌面环境
                startDesktop();

                Thread.sleep(3000); // 等待启动
                callback.onStarted();
            } catch (Exception e) {
                Log.e(TAG, "Start error", e);
                callback.onError(e.getMessage());
            }
        }).start();
    }

    private void installContainer() throws IOException, InterruptedException {
        File rootfs = new File(filesDir, ROOTFS_FILENAME);
        String installCmd = String.format(
            "proot-distro install %s --tarball %s",
            CONTAINER_NAME, rootfs.getAbsolutePath()
        );
        executeCommand(installCmd);
    }

    private void startDesktop() throws IOException, InterruptedException {
        String startCmd = String.format(
            "proot-distro login %s -- bash -c '" +
            "export DISPLAY=:1 && " +
            "Xvfb :1 -screen 0 1080x1920x24 & " +
            "sleep 2 && " +
            "gnome-session & " +
            "x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &" +
            "'",
            CONTAINER_NAME
        );
        currentProcess = Runtime.getRuntime().exec(new String[]{"sh", "-c", startCmd});
    }

    public void stopYuloOS() {
        try {
            if (currentProcess != null) {
                currentProcess.destroy();
                currentProcess = null;
            }
            executeCommand("pkill -f Xvfb");
            executeCommand("pkill -f x11vnc");
            executeCommand("pkill -f gnome-session");
        } catch (Exception e) {
            Log.e(TAG, "Stop error", e);
        }
    }

    private String executeCommand(String command) throws IOException, InterruptedException {
        Process process = Runtime.getRuntime().exec(new String[]{"sh", "-c", command});
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        StringBuilder output = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            output.append(line).append("\n");
        }
        process.waitFor();
        return output.toString();
    }

    public void cleanup() {
        stopYuloOS();
    }
}
