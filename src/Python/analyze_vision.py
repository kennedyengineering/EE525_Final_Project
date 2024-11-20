# Analyze pendulum swing from vision/ data collection

import numpy as np
import cv2 as cv

filename = "data/vision/swing_pendulum_vision_video_1.MOV"

clicked_coordinates = []

def click_event(event, x, y, flags, params):
    global clicked_coordinates

    if event == cv.EVENT_LBUTTONDOWN:  # Check for left mouse click
        # Store the coordinates of the click
        clicked_coordinates = [(x, y)]

def get_click_coordinates(image):
    global clicked_coordinates

    # Display the image
    cv.imshow("Select Pendulum Top", image)

    # Set the mouse callback function
    cv.setMouseCallback("Select Pendulum Top", click_event)

    # Wait for key press or mouse click events
    while True:
        # Wait for a key event or mouse event (non-blocking)
        if cv.waitKey(1) & 0xFF == ord('q'):  # Press 'q' to quit
            break
        if clicked_coordinates:  # If a click has been registered
            break

    cv.destroyAllWindows()

    return clicked_coordinates

# Open video file
cap = cv.VideoCapture(filename)
if not cap.isOpened():
    print("Cannot open camera")
    exit()

while True:
    # Capture frame-by-frame
    ret, frame = cap.read()

    # if frame is read correctly ret is True
    if not ret:
        print("Can't receive frame (stream end?). Exiting ...")
        break

    # determine pendulum swing point
    if not clicked_coordinates and not get_click_coordinates(frame):
        break

    # Our operations on the frame come here
    blurred = cv.GaussianBlur(frame, (7, 7), 0)
    hsv = cv.cvtColor(blurred, cv.COLOR_BGR2HSV)

    # set the bounds for the red hue
    lower_red = np.array([150,190,110])
    upper_red = np.array([180,255,255])

    # create a mask using the bounds set
    mask = cv.inRange(hsv, lower_red, upper_red)
    # create an inverse of the mask
    mask_inv = cv.bitwise_not(mask)
    # Filter only the red colour from the original image using the mask
    res = cv.bitwise_and(frame, frame, mask=mask)

    # find contour
    contours, _ = cv.findContours(mask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
    contour = max(contours, key=cv.contourArea)

    # Get the minimum enclosing circle
    (x, y), radius = cv.minEnclosingCircle(contour)

    # Draw the circle on the image (convert center to int)
    center = (int(x), int(y))
    radius = int(radius)

    # Draw the circle and its center on the image
    cv.circle(frame, center, radius, (0, 255, 0), 2)  # Green circle

    # Draw the rest of the pendulum
    cv.line(frame, clicked_coordinates[0], center, (0, 255, 0), 2)

    # Display the resulting frame
    cv.imshow('Pendulum Visual Analysis', frame)
    if cv.waitKey(1) == ord('q'):
        break

# When everything done, release the capture
cap.release()
cv.destroyAllWindows()
