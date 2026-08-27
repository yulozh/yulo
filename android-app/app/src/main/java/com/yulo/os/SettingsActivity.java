package com.yulo.os;

import android.os.Bundle;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.preference.PreferenceFragmentCompat;

public class SettingsActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        if (savedInstanceState == null) {
            getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.settings_container, new SettingsFragment())
                .commit();
        }

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("设置");
        }
    }

    @Override
    public boolean onSupportNavigateUp() {
        finish();
        return true;
    }

    public static class SettingsFragment extends PreferenceFragmentCompat {
        @Override
        public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
            setPreferencesFromResource(R.xml.preferences, rootKey);

            // 分辨率设置
            androidx.preference.ListPreference resolutionPref = findPreference("resolution");
            if (resolutionPref != null) {
                resolutionPref.setOnPreferenceChangeListener((preference, newValue) -> {
                    Toast.makeText(getContext(), "分辨率: " + newValue, Toast.LENGTH_SHORT).show();
                    return true;
                });
            }

            // 性能模式
            androidx.preference.ListPreference performancePref = findPreference("performance_mode");
            if (performancePref != null) {
                performancePref.setOnPreferenceChangeListener((preference, newValue) -> {
                    Toast.makeText(getContext(), "性能模式: " + newValue, Toast.LENGTH_SHORT).show();
                    return true;
                });
            }

            // 清除数据
            androidx.preference.Preference clearPref = findPreference("clear_data");
            if (clearPref != null) {
                clearPref.setOnPreferenceClickListener(preference -> {
                    new android.app.AlertDialog.Builder(requireContext())
                        .setTitle("清除数据")
                        .setMessage("确定要删除 yulo OS 系统文件吗？这将需要重新下载。")
                        .setPositiveButton("确定", (dialog, which) -> {
                            Toast.makeText(getContext(), "数据已清除", Toast.LENGTH_SHORT).show();
                        })
                        .setNegativeButton("取消", null)
                        .show();
                    return true;
                });
            }

            // 关于
            androidx.preference.Preference aboutPref = findPreference("about");
            if (aboutPref != null) {
                aboutPref.setSummary("yulo OS 1.0 (Sakura)\n基于 Ubuntu 26.04\n樱花粉主题");
            }
        }
    }
}
