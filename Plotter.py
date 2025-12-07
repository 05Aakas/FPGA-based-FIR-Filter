import serial 
import numpy as np 
import matplotlib.pyplot as plt 
from collections import deque 
import time 
 
# Configure Serial Port 
ser = serial.Serial("COM3", 115200, timeout=1) 
 
# Store Data for Plotting 
buffer_size = 200 
filtered_wave = deque([0] * buffer_size, maxlen=buffer_size) 
 
# Setup interactive plot with better backend 
plt.ion() 
plt.figure(figsize=(10, 5)) 
plt.title("Real-Time Filtered Data") 
plt.xlabel("Sample Number") 
plt.ylabel("Amplitude") 
plt.grid(True) 
plt.ylim(-32768, 32767) 
line, = plt.plot([], [], 'b-', label="Filtered Wave") 
plt.legend() 
 
# Track last update time 
last_update = time.time() 
update_interval = 0.05  # Update plot every 50ms 
 
try: 
    while True: 
 # Read 2 Bytes 
 data = ser.read(2) 
        if len(data) == 2: 
            # Print raw bytes for debugging 
#             print(f"Raw bytes: {data}") 
             
            # Convert to signed 16-bit integer 
            filt_val = int.from_bytes(data, byteorder='little', signed=True) 
#             print(f"Converted value: {filt_val}") 
            filtered_wave.append(filt_val) 
             
            # Only update plot at intervals to reduce CPU load 
            current_time = time.time() 
            if current_time - last_update >= update_interval: 
                # Update plot data 
                line.set_data(np.arange(len(filtered_wave)), filtered_wave) 
                 
               # Adjust view 
                ax = plt.gca() 
                ax.relim() 
 
 
 
                ax.autoscale_view(scalex=False, scaley=False) 
               ax.set_xlim(0, buffer_size) 
                 
               # Force redraw 
               plt.draw() 
               plt.pause(0.001) 
               last_update = current_time 
 
except KeyboardInterrupt: 
print("\nStopping...") 
finally: 
ser.close() 
plt.ioff() 
plt.show()