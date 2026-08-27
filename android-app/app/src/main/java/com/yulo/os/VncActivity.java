package com.yulo.os;

import android.os.Bundle;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

public class VncActivity extends AppCompatActivity {

    private FrameLayout vncContainer;
    private TouchHandler touchHandler;
    private GestureDetector gestureDetector;
    private ScaleGestureDetector scaleGestureDetector;
    private View vncView;

    private float scale = 1.0f;
    private float translationX = 0f;
    private float translationY = 0f;

    private static final float MIN_SCALE = 0.5f;
    private static final float MAX_SCALE = 3.0f;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_vnc);

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN |
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        vncContainer = findViewById(R.id.vnc_container);
        vncView = findViewById(R.id.vnc_view);
        ImageButton btnBack = findViewById(R.id.btn_back);
        ImageButton btnKeyboard = findViewById(R.id.btn_keyboard);
        ImageButton btnZoom = findViewById(R.id.btn_zoom);
        TextView tvHint = findViewById(R.id.tv_hint);

        touchHandler = new TouchHandler(this);

        gestureDetector = new GestureDetector(this, new GestureListener());
        scaleGestureDetector = new ScaleGestureDetector(this, new ScaleListener());

        vncContainer.setOnTouchListener((v, event) -> {
            gestureDetector.onTouchEvent(event);
            scaleGestureDetector.onTouchEvent(event);
            handleTouch(event);
            return true;
        });

        btnBack.setOnClickListener(v -> finish());
        btnKeyboard.setOnClickListener(v -> toggleKeyboard());
        btnZoom.setOnClickListener(v -> resetZoom());

        tvHint.setText("单指点击=左键 | 长按=右键 | 双指滚动 | 三指多任务");
    }

    private void handleTouch(MotionEvent event) {
        int pointerCount = event.getPointerCount();

        switch (pointerCount) {
            case 1:
                // 单指操作由 GestureDetector 处理
                break;
            case 2:
                // 双指操作由 ScaleGestureDetector 和滚动处理
                handleTwoFingerScroll(event);
                break;
            case 3:
                // 三指操作
                handleThreeFinger(event);
                break;
        }
    }

    private void handleTwoFingerScroll(MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_MOVE) {
            float dx = event.getX(0) - event.getX(1);
            float dy = event.getY(0) - event.getY(1);
            // 发送滚轮事件
            touchHandler.sendScroll((int) dy, (int) dx);
        }
    }

    private void handleThreeFinger(MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_MOVE) {
            float dy = event.getY(0) - event.getY(1);
            if (dy < -50) {
                // 三指上滑 - 活动概览
                touchHandler.sendKeyCombo("Super");
                Toast.makeText(this, "活动概览", Toast.LENGTH_SHORT).show();
            } else if (dy > 50) {
                // 三指下滑 - 显示桌面
                touchHandler.sendKeyCombo("Super+d");
                Toast.makeText(this, "显示桌面", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private class GestureListener extends GestureDetector.SimpleOnGestureListener {
        @Override
        public boolean onSingleTapConfirmed(MotionEvent e) {
            touchHandler.sendClick((int) e.getX(), (int) e.getY(), 1);
            return true;
        }

        @Override
        public boolean onDoubleTap(MotionEvent e) {
            touchHandler.sendClick((int) e.getX(), (int) e.getY(), 2);
            return true;
        }

        @Override
        public void onLongPress(MotionEvent e) {
            touchHandler.sendRightClick((int) e.getX(), (int) e.getY());
            Toast.makeText(VncActivity.this, "右键菜单", Toast.LENGTH_SHORT).show();
        }

        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
            if (e1 != null && e2 != null && e1.getPointerCount() == 1) {
                // 单指拖动
                touchHandler.sendDrag(
                    (int) e1.getX(), (int) e1.getY(),
                    (int) e2.getX(), (int) e2.getY()
                );
            }
            return true;
        }

        @Override
        public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
            // 从左边缘右滑 = 返回
            if (e1 != null && e1.getX() < 50 && velocityX > 500) {
                finish();
                return true;
            }
            // 从底部上滑 = 应用列表
            if (e1 != null && e1.getY() > vncContainer.getHeight() - 100 && velocityY < -500) {
                touchHandler.sendKeyCombo("Super+a");
                Toast.makeText(VncActivity.this, "应用列表", Toast.LENGTH_SHORT).show();
                return true;
            }
            // 从顶部下滑 = 通知
            if (e1 != null && e1.getY() < 100 && velocityY > 500) {
                touchHandler.sendKeyCombo("Super+n");
                Toast.makeText(VncActivity.this, "通知中心", Toast.LENGTH_SHORT).show();
                return true;
            }
            return false;
        }
    }

    private class ScaleListener extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            scale *= detector.getScaleFactor();
            scale = Math.max(MIN_SCALE, Math.min(MAX_SCALE, scale));
            vncView.setScaleX(scale);
            vncView.setScaleY(scale);
            return true;
        }
    }

    private void toggleKeyboard() {
        touchHandler.toggleKeyboard();
    }

    private void resetZoom() {
        scale = 1.0f;
        translationX = 0f;
        translationY = 0f;
        vncView.setScaleX(1f);
        vncView.setScaleY(1f);
        vncView.setTranslationX(0f);
        vncView.setTranslationY(0f);
        Toast.makeText(this, "缩放已重置", Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }
}
