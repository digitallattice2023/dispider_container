#!/usr/bin/env bash
set -e

# 路径可能需要根据您的安装调整
NOVNC_DIR="/opt/novnc"
INDEX_PATH="${NOVNC_DIR}/index.html"
VNC_HTML_PATH="${NOVNC_DIR}/vnc.html"

# 选择正确的 HTML 文件
if [ -f "$INDEX_PATH" ]; then
  HTML_PATH="$INDEX_PATH"
elif [ -f "$VNC_HTML_PATH" ]; then
  HTML_PATH="$VNC_HTML_PATH"
else
  echo "找不到 noVNC HTML 文件"
  exit 1
fi

echo "找到 HTML 文件: $HTML_PATH"

# 检查界面元素
echo "正在检查 noVNC 界面元素..."
grep -o "id=\"screen\"" "$HTML_PATH" || echo "未找到 id='screen' 元素，将尝试使用 canvas 元素"

# 使用单行 sed 命令直接插入 JavaScript
sed -i '/<\/body>/i <script>\
(function() {\
  /* 自适应缩放功能 */\
  window.addEventListener("load", function() {\
    var UI = window.UI || {};\
    \
    /* 查找屏幕元素 */\
    function findScreenElement() {\
      var screenElement = document.getElementById("screen");\
    /* 调整屏幕大小的函数 */\
    function resizeScreen() {\
      var screenElement = findScreenElement();\
      if (screenElement) {\
        console.log("找到屏幕元素，正在调整大小...");\
        var deviceWidth = document.body.clientWidth;\
        var deviceHeight = document.body.clientHeight;\
        console.log("deviceWidth");\
        console.log("deviceHeight");\
        screenElement.style.width = deviceWidth + "px";\
        screenElement.style.height = (deviceHeight - 109) + "px";\
        \
        /* 同时设置 RFB 对象的缩放属性 */\
        if (UI.rfb) {\
          UI.rfb.scaleViewport = true;\
          UI.rfb.resizeSession = true;\
          UI.rfb.qualityLevel = 6;\
          if (typeof UI.updateViewOnly === "function") {\
            UI.updateViewOnly();\
          }\
        }\
      } else {\
        console.log("未找到屏幕元素");\
      }\
    }\
    \
    /* 页面加载和窗口大小改变时调整大小 */\
    setTimeout(resizeScreen, 1000);\
    window.addEventListener("resize", resizeScreen);\
    \
    /* 修改 UI.init 方法以设置 RFB 属性 */\
    if (UI.init) {\
      var origUiInit = UI.init;\
      UI.init = function() {\
        var result = origUiInit.apply(this, arguments);\
        if (UI.rfb) {\
          UI.rfb.scaleViewport = true;\
          UI.rfb.resizeSession = true;\
          setTimeout(resizeScreen, 500);\
        }\
        return result;\
      };\
    }\
  });\
})();\
</script>' "$HTML_PATH"

echo "已添加自适应缩放功能到 noVNC"

# 检查修改后的文件
echo "修改后的 HTML 文件尾部内容:"
tail -n 20 "$HTML_PATH"

# 在脚本末尾添加
echo "noVNC 版本信息:"
grep -o "version.*" "$HTML_PATH" || echo "无法确定 noVNC 版本"

echo "主要 HTML 结构:"
grep -o "<div id=\".*\"" "$HTML_PATH"