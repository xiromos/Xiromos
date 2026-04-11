def get_command():
    if cli == "print":
        print("Enter a String to output: ")
        string = input(">> ")

        print(">>> " + string + " <<<")
    
    elif cli == "exit":
            print("Exiting program :(...")
            running = False

    elif cli == "calc":
        value1 = int(input("Type your first number > "))
        value2 = int(input("Type your second number >> "))
        print("Calculating...")

        print("ADD > ")
        print(value1 + value2)
        print("SUB > ")
        print(value1 - value2)
        print("MUL > ")
        print(value1 * value2)
        print("DIV > ")
        print(value1 / value2)

        print("Returning to interpreter...")
    elif cli == "help":
        print("---- About Program ----\n" + 
              "Command Interpreter v0.1\n" + 
              "This is a program which lets\n" + 
              "you type simple commands and\n" + 
              "print some output\n" + 
              "-----------------------\n" + 
              "Commands: \n" + 
              "-print\n" + 
              "-exit\n"
              "-calc\n"
              "-help")
    else:
        print("Sorry but unknown command")

running = True
i = 0
print("Command Interpreter - Technodon")
while running == True:
    cli = input("> ")
    get_command()

    i + 1
    if i == 10:
        running = False
        