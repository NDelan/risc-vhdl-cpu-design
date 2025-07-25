import java.io.FileWriter;
import java.io.IOException;

public class MemoryInitializer {

    // Constants for Memory Initialization File (MIF) format
    private static final int MEMORY_DEPTH = 256;
    private int dataWidth;
    private String dataType;
    private String outputFileName;
    private Object[] inputData;

    // Constructor to initialize the MemoryInitializer
    public MemoryInitializer(Object[] inputData, String dataType, int dataWidth, String outputFileName) {
        // Initialize instance variables
        this.inputData = inputData;
        this.dataType = dataType;
        this.dataWidth = dataWidth;
        this.outputFileName = outputFileName;
    }

    // Converts data based on its type to binary format
    private String convertToBinary(Object data) {
        if (dataType.equals("decimal")) {
            // Convert decimal to binary and pad with zeros
            return String.format("%" + dataWidth + "s", Integer.toBinaryString((int) data)).replace(' ', '0');
        } else if (dataType.equals("hexadecimal")) {
            // Convert hexadecimal to binary and pad with zeros
            return String.format("%" + dataWidth + "s", Integer.toBinaryString(Integer.parseInt((String) data, 16))).replace(' ', '0');
        } else if (dataType.equals("binary")) {
            // Ensure binary data is padded with zeros
            return String.format("%" + dataWidth + "s", data).replace(' ', '0');
        } else {
            // Unsupported data type
            throw new IllegalArgumentException("Data type not supported.");
        }
    }

    // Generates MIF file from initialized data
    public void generateMemoryInitializationFile() throws IOException {
        // MIF file header and footer
        String mifHeader = "DEPTH = " + MEMORY_DEPTH + ";\nWIDTH = " + dataWidth + ";\nADDRESS_RADIX = HEX;\nDATA_RADIX = BIN;\nCONTENT\nBEGIN\n";
        String mifFooter = "END\n";

        try (FileWriter mifFileWriter = new FileWriter(outputFileName)) {
            // Write the MIF file with specified header and footer
            mifFileWriter.write(mifHeader);

            // Iterate through the data and write address and binary data to the MIF file
            for (int i = 0; i < inputData.length; i++) {
                String addressHex = String.format("%02X", i); // Format address in hexadecimal with leading zeros
                String dataBinary = convertToBinary(inputData[i]); // Convert data to binary
                mifFileWriter.write(addressHex + " : " + dataBinary + ";\n");
            }

            mifFileWriter.write(mifFooter);
        }
    }

    // Main method to demonstrate the usage of the MemoryInitializer class
    public static void main(String[] args) throws IOException {
        // Test cases with different data, data types, and output filenames
        Object[][] testData = {
                {100, 50, 25, 75, 200, 0},
                {"2A", "1E", "3F", "5D", "A0", "7B"},
                {"110110", "001011", "111100", "010101"}
        };

        String[] dataTypes = {"decimal", "hexadecimal", "binary"};
        String[] outputFiles = {"memory_data.mif", "hex_memory_data.mif", "binary_memory_data.mif"};

        // Generate MIF files for each test case
        for (int i = 0; i < testData.length; i++) {
            MemoryInitializer memoryInitializer = new MemoryInitializer(testData[i], dataTypes[i], 6, outputFiles[i]);
            memoryInitializer.generateMemoryInitializationFile();
        }
    }
}



