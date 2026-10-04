timeout 15 bash -c 'exec 3<>/dev/tcp/152.70.131.86/22 && head -c 40 <&3' && echo " || BANNER_OK" || echo "BANNER_FAIL"
