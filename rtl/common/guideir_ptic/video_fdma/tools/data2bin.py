DATA_FORMAT = "big"

filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\BasicModule\guideir_ptic\video_fdma\sim\data\20241109\20230305_201927_2204_9_76_15_8564_x16_x.dat"

def dat2hex(filename):
    with open(filename, 'rb') as f:
        data = f.readlines()
        data = [line.strip().decode('utf-8') for line in data]
        data_split = []
        if DATA_FORMAT == "big":
            for i in range(len(data)):
                data_split.append(data[i][0:2])
                data_split.append(data[i][2:4])
        else:
            for i in range(len(data)):
                data_split.append(data[i][2:4])
                data_split.append(data[i][0:2])


        with open(r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\BasicModule\guideir_ptic\video_fdma\sim\data\20241109\test.hex", "w") as f:
            for i in range(len(data_split)):
                f.write(data_split[i])
                f.write("\n")
def main():
    dat2hex(filename)


if __name__ == "__main__":
    main()
