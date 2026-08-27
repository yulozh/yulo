package com.yulo.os;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.widget.Toast;

import java.io.DataOutputStream;
import java.io.IOException;

/**
 * yulo OS 触摸处理器
 * 将触摸手势转换为鼠标/键盘事件
 */
public class TouchHandler {

    private static final String TAG = "TouchHandler";
    private Context context;
    private Handler mainHandler;

    // 鼠标状态
    private int lastX = 0;
    private int lastY = 0;
    private boolean isDragging = false;
    private boolean isRightButtonDown = false;

    public TouchHandler(Context context) {
        this.context = context;
        this.mainHandler = new Handler(Looper.getMainLooper());
    }

    /**
     * 发送鼠标左键点击
     */
    public void sendClick(int x, int y, int clickCount) {
        moveMouse(x, y);
        try {
            for (int i = 0; i < clickCount; i++) {
                executeXdotool("mousedown 1");
                Thread.sleep(50);
                executeXdotool("mouseup 1");
                if (i < clickCount - 1) Thread.sleep(100);
            }
        } catch (InterruptedException e) {
            Log.e(TAG, "Click error", e);
        }
    }

    /**
     * 发送鼠标右键点击
     */
    public void sendRightClick(int x, int y) {
        moveMouse(x, y);
        try {
            executeXdotool("mousedown 3");
            Thread.sleep(100);
            executeXdotool("mouseup 3");
        } catch (InterruptedException e) {
            Log.e(TAG, "Right click error", e);
        }
    }

    /**
     * 发送鼠标拖动
     */
    public void sendDrag(int startX, int startY, int endX, int endY) {
        if (!isDragging) {
            moveMouse(startX, startY);
            executeXdotool("mousedown 1");
            isDragging = true;
        }
        moveMouse(endX, endY);

        // 如果手指抬起，结束拖动
        // 这个逻辑由 VncActivity 的 ACTION_UP 处理
    }

    /**
     * 结束拖动
     */
    public void endDrag() {
        if (isDragging) {
            executeXdotool("mouseup 1");
            isDragging = false;
        }
    }

    /**
     * 发送滚轮事件
     */
    public void sendScroll(int deltaY, int deltaX) {
        // 垂直滚动
        if (Math.abs(deltaY) > 5) {
            String button = deltaY > 0 ? "4" : "5"; // 4=上, 5=下
            int count = Math.min(Math.abs(deltaY) / 20, 5);
            for (int i = 0; i < count; i++) {
                executeXdotool("click " + button);
            }
        }
        // 水平滚动
        if (Math.abs(deltaX) > 5) {
            String button = deltaX > 0 ? "6" : "7"; // 6=左, 7=右
            int count = Math.min(Math.abs(deltaX) / 20, 5);
            for (int i = 0; i < count; i++) {
                executeXdotool("click " + button);
            }
        }
    }

    /**
     * 发送键盘组合键
     */
    public void sendKeyCombo(String keys) {
        executeXdotool("key " + keys);
    }

    /**
     * 移动鼠标
     */
    private void moveMouse(int x, int y) {
        lastX = x;
        lastY = y;
        executeXdotool("mousemove " + x + " " + y);
    }

    /**
     * 切换软键盘
     */
    public void toggleKeyboard() {
        InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) {
            imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
        }
    }

    /**
     * 执行 xdotool 命令
     * 通过 proot 容器内的 xdotool 发送事件
     */
    private void executeXdotool(String command) {
        try {
            String fullCmd = String.format(
                "proot-distro login yulo -- bash -c 'export DISPLAY=:1 && xdotool %s'",
                command
            );
            Process process = Runtime.getRuntime().exec(new String[]{"sh", "-c", fullCmd});
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "xdotool error: " + command, e);
        }
    }

    /**
     * 清理资源
     */
    public void cleanup() {
        endDrag();
    }
}
