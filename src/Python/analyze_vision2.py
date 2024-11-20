# Analyze pendulum swing from vision/ data collection

import numpy as np
import cv2 as cv

filename = "data/vision2/ethernet_pendulum_video_3.MOV"

marker_rect_top_length_inches = 30
marker_rect_side_length_inches = 18.75

pixels_per_inch = 20
marker_rect_top_length_pixels = marker_rect_top_length_inches * pixels_per_inch
marker_rect_side_length_pixels = marker_rect_side_length_inches * pixels_per_inch

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

H = None

while True:
    # Capture frame-by-frame
    ret, frame = cap.read()

    # if frame is read correctly ret is True
    if not ret:
        print("Can't receive frame (stream end?). Exiting ...")
        break

    # determine homography from markers
    if H is None:

        # mask out bottom of frame
        fh, fw, _ = frame.shape

        mask = np.ones((fh, fw), dtype=np.uint8) * 255
        x, y, w, h = 0, fh-600, fw, 600
        mask[y:y+h, x:x+w] = 0

        masked_frame = cv.bitwise_and(frame, frame, mask=mask)

        # blur frame
        blurred = cv.GaussianBlur(masked_frame, (7, 7), 0)

        # convert color space
        hsv = cv.cvtColor(blurred, cv.COLOR_BGR2HSV)

        # mask for markers
        lower_marker = np.array([0, 50, 225])
        upper_marker = np.array([180, 255, 255])

        mask = cv.inRange(hsv, lower_marker, upper_marker)

        # find marker contours
        contours, _ = cv.findContours(mask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
        contours = sorted(contours, key=cv.contourArea, reverse=True)[:4]

        # find marker centers
        marker_coordinates = []
        for contour in contours:
            # get the minimum enclosing circle
            (x, y), radius = cv.minEnclosingCircle(contour)

            # store results
            center = (int(x), int(y))
            marker_coordinates.append(center)

        # sort marker centers
        centroid = np.mean(marker_coordinates, axis=0)

        def angle_from_centroid(point, centroid):
            return np.arctan2(point[1] - centroid[1], point[0] - centroid[0])

        marker_coordinates = sorted(marker_coordinates, key=lambda p: angle_from_centroid(p, centroid))

        # compute homography
        vertices = np.array(marker_coordinates)

        dest_vertices = np.array([(0,0),
                                  (marker_rect_top_length_pixels, 0),
                                  (marker_rect_top_length_pixels, marker_rect_side_length_pixels),
                                  (0,marker_rect_side_length_pixels),
                                  ])

        H, _ = cv.findHomography(vertices, dest_vertices)

    # warp and crop image
    frame = cv.warpPerspective(frame, H, (fw, fh))
    frame = frame[0:int(marker_rect_side_length_pixels), 0:int(marker_rect_top_length_pixels)]

    # determine pendulum swing point
    if not clicked_coordinates and not get_click_coordinates(frame):
        break

    # Our operations on the frame come here
    blurred = cv.GaussianBlur(frame, (7, 7), 0)
    hsv = cv.cvtColor(blurred, cv.COLOR_BGR2HSV)

    # set the bounds for the green hue
    lower_green = np.array([35, 50, 50])
    upper_green = np.array([85, 255,255])

    # create a mask using the bounds set
    mask = cv.inRange(hsv, lower_green, upper_green)

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
