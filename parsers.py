# Handle Sword/Shield equipment
def get_ss(num):
    tmp = []
    num = bin(int(num)).replace("0b", "")
    if len(num) != 7:
        num = ("0"*(7-len(num))) + num
    tmp.append(59) if num[6] == '1' else tmp.append(255)
    tmp.append(60) if num[5] == '1' else tmp.append(255)
    tmp.append(61) if num[4] == '1' else tmp.append(255)
    tmp.append(62) if num[2] == '1' else tmp.append(255)
    tmp.append(63) if num[1] == '1' else tmp.append(255)
    tmp.append(64) if num[0] == '1' else tmp.append(255)
    return tmp

# Handle Tunic/Boots equipment
def get_tb(num):
    tmp = []
    num = bin(int(num)).replace("0b", "")
    if len(num) != 7:
        num = ("0"*(7-len(num))) + num
    tmp.append(65) if num[6] == '1' else tmp.append(255)
    tmp.append(66) if num[5] == '1' else tmp.append(255)
    tmp.append(67) if num[4] == '1' else tmp.append(255)
    tmp.append(68) if num[2] == '1' else tmp.append(255)
    tmp.append(69) if num[1] == '1' else tmp.append(255)
    tmp.append(70) if num[0] == '1' else tmp.append(255)
    return tmp

# Handle Upgrades
def get_up(num):
    tmp = ""
    for n in num:
        try:
            if len(bin(int(n)).replace('0b', '')) != 8:
                tmp += ("0"*(8-len(bin(int(n)).replace('0b', '')))) + bin(int(n)).replace('0b', '')
            else:
                tmp += bin(int(n)).replace('0b', '')
        except:
            pass
    num = tmp
    tmp = []
    if len(num) != 32:
        num = ("0"*(32-len(num))) + num

    # Quiver
    if num[31] == '1':
        tmp.append(74)
    elif num[30] == '1':
        tmp.append(75)
    elif num[29] == '1':
        tmp.append(76)
    else:
        tmp.append(255)
    # Bomb Bag
    if num[28] == '1':
        tmp.append(77)
    elif num[27] == '1':
        tmp.append(78)
    elif num[26] == '1':
        tmp.append(79)
    else:
        tmp.append(255)
    # Gauntlet
    if num[25] == '1':
        tmp.append(80)
    elif num[24] == '1':
        tmp.append(81)
    elif num[23] == '1':
        tmp.append(82)
    else:
        tmp.append(255)
    # Scale
    if num[22] == '1':
        tmp.append(83)
    elif num[21] == '1':
        tmp.append(84)
    else:
        tmp.append(255)
    # Wallet
    if num[19] == '1':
        tmp.append(86)
    elif num[18] == '1':
        tmp.append(87)
    else:
        tmp.append(255)
    # Bullet Bag?
    if num[17] == '1':
        tmp.append(71)
    elif num[16] == '1':
        tmp.append(72)
    elif num[15] == '1':
        tmp.append(73)
    else:
        tmp.append(255)

    return tmp

# Handle Quest Items
def get_qi(num):
    tmp = ""
    for n in num:
        tmp += bin(int(n)).replace('0b', '')
    num = tmp
    tmp = []
    if len(num) != 32:
        num = ("0"*(32-len(num))) + num
    # Normal songs
    for i in range(6):
        tmp.append(96+i) if num[19-i] == '1' else tmp.append(255)
    # Warp songs
    for i in range(6):
        tmp.append(90+i) if num[25-i] == '1' else tmp.append(255)
    # Meallions
    for i in range(6):
        tmp.append(102+i) if num[31-i] == '1' else tmp.append(255)
    # Stones
    for i in range(3):
        tmp.append(108+i) if num[13-i] == '1' else tmp.append(255)
    # Stone of Agony and Geurudo Card
    for i in range(2):
        tmp.append(111+i) if num[10-i] == '1' else tmp.append(255)

    return tmp
