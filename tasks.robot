*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             Dialogs
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Go to Order Robot Screen
    FOR    ${robot}    IN    @{orders}
        Fill Form    ${robot}
        Preview Robot
        ${screenshot}=    Take a screenshot of the robot    ${robot}[Order number]
        Wait Until Keyword Succeeds    10    0.5 s    Place Robot Order    ${robot}[Order number]
        ${pdf}=    Store the receipt as a PDF file    ${robot}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END
    Create ZIP package from PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    css:div.alert-buttons > button.btn.btn-dark
    Click Button    OK

Fill Form
    [Arguments]    ${robot}
    Log    Ordering ${robot}
    Select From List By Value    head    ${robot}[Head]
    Select Radio Button    body    ${robot}[Body]
    Input Text    css:input[type="number"]    ${robot}[Legs]
    Input Text    address    ${robot}[Address]

Go to Order Robot Screen
    Click Link    Order your robot!
    Close the annoying modal

Order another robot
    Click Button    Order another robot
    Close the annoying modal

Preview Robot
    Click Button    Preview
    ${robot_image_html}=    Get Element Attribute    robot-preview-image    outerHTML

Place Robot Order
    [Arguments]    ${id}
    Log to Console    Placing Robot Order #${id}
    Click Button    Order
    Wait Until Element Is Visible    receipt    timeout=0.1s

Store the receipt as a PDF file
    [Arguments]    ${order number}
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}${order number}-receipt.pdf
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order number}
    ${screenshot}=    Set Variable    ${OUTPUT_DIR}${/}${order number}-image.png
    Screenshot    css:#robot-preview-image    filename=${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=${True}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}robot_receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file_name}    include=*.pdf
