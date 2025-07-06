import shutil
import cv2
import os
import pathlib
# Author: @Lunastela

# Generates multiple palette shaders for convenience purposes.
# Because we may not be able to use uniform values, as well as multiple samplers, each possible palette must be generated into its own shader.
# For convenience I have made this script to automate the generation of palettes.

# Prerequisites: coloroffset.vs and coloroffset.fs
# A modified version of coloroffset.fs will be provided. coloroffset.vs is the same as the one provided by the game itself.

localpath = str(pathlib.Path(__file__).parent.resolve())
# Obtain all possible palettes from the current folder
for file in os.listdir(localpath):
    if file.endswith(".png"):
        # Set the current image to said palette
        img = cv2.imread(localpath + "\\" + file)
        # Obtain and generate a folder (if none exists) for said palette
        filename = file[:-4] # Stripped file name lacking extension
        folderDir = localpath + "\\" + filename
        if not os.path.exists(folderDir):
            os.makedirs(folderDir)
        # Obtain the height and width of the image
        height, width = img.shape[:2]
        for j in range(1, width):
            # Copy vertex shader for the current palette
            shutil.copy2(localpath + "\\coloroffset.vs", 
                        folderDir + "\\{}.vs".format(filename + str(j)))
            
            # Cache the intended parts from the original color offset shader
            originalFragmentShader = open(localpath + "\\coloroffset.fs", "r")
            cachedFragmentShader = originalFragmentShader.read()
            # Split the code into a list that contains the parts of the code before and after the divider
            shaderDivider = "// APPEND CODE HERE"
            fragmentShaderParts = cachedFragmentShader.split(shaderDivider, 1)
            # Close the shader file and continue with the process
            originalFragmentShader.close()

            # Create a fragment shader for the current palette
            curFragmentShader = open(folderDir + "\\{}.fs".format(filename + str(j)), "w")
            curFragmentShader.write(fragmentShaderParts[0])

            # Loop through width and height of image to generate palettes
            curFragmentShader.write("// Excuse the poorly generated code, see paletteshadergen.py for more info\n    ")
            for i in range(height):
                # Obtain pixel color value
                (B, G, R) = img[i, j]
                (oB, oG, oR) = img[i, 0]
                # Write code that swaps the palette of pixel colors
                currentLine = "if (distance(textureColor.rgb, vec3({}, {}, {})) <= 0.1)\n    ".format(oR / 256, oG / 256, oB / 256)
                currentLine += "    textureColor = vec4({}, {}, {}, textureColor.a);\n    ".format(R / 256, G / 256, B / 256)
                # Do not allow consecutive palette swaps to take place
                if i < height - 1:
                    currentLine += "else "
                curFragmentShader.write(currentLine)

            # Close the current fragment shader
            curFragmentShader.write(fragmentShaderParts[1])
            curFragmentShader.close()