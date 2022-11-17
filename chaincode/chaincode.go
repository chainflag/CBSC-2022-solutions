package main

import (
	"encoding/json"
	"fmt"
	"github.com/fabric/core/chaincode/shim"
	pb "github.com/fabric/protos/peer"
	"strconv"
	"strings"
	"sync"
)

type FileChain struct {
	Id            string
	AuthorId      string
	OperationDate string
	OperationType string
}

type ReadChain struct {
	Id            string
	DocumentId    string
	AuthorId      string
	OperationDate string
	OperationType string
	ScoreVal      string
}

type FileChainDown struct {
	Id            string
	DocumentId    string
	AuthorId      string
	OperationDate string
	OperationType string
	ScoreVal      string
	ReadUserId    string
	ReadUserScore string
}

type Statistical struct {
	DownloadNum   int
	UploadFileNum int
	ReadFileNum   int
}

func (t *FileChain) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fun, args := stub.GetFunctionAndParameters()
	fmt.Println("ex02 ", fun)

	dNum, _ := strconv.Atoi(args[0])
	uNum, _ := strconv.Atoi(args[1])
	rNum, _ := strconv.Atoi(args[2])

	statistical := Statistical{
		dNum,
		uNum,
		rNum}
	bytes, err := json.Marshal(statistical)
	if err != nil {
		return shim.Error("00002")
	}
	err = stub.PutState("statistical", bytes)
	return shim.Success(nil)
}

func (t *FileChain) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println("ex02 Invoke", function)
	if function == "uploadFile" {
		return t.uploadFile(stub, args)
	} else if function == "readFile" {
		return t.readFile(stub, args)
	} else if function == "downloadFile" {
		return t.downloadFile(stub, args)
	} else if function == "deleteReadFile" {
		return t.deleteReadFile(stub, args)
	} else if function == "deleteUploadFile" {
		return t.deleteUploadFile(stub, args)
	} else if function == "deleteDownloadFile" {
		return t.deleteDownloadFile(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	} else if function == "delete" {
		return t.delete(stub, args)
	}
	return shim.Error("Invalid invoke function name")
}

/**upload*/
func (t *FileChain) uploadFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	if len(args) != 4 {
		return shim.Error("00001")
	}
	fileChain := FileChain{args[0], args[1], args[2], args[3]}
	bytes, err := json.Marshal(fileChain)
	if err != nil {
		return shim.Error("00002")
	}

	err = stub.PutState("uploadFile_"+args[0], bytes)
	if err != nil {
		return shim.Error("00003")
	}
	state, err := stub.GetState("statistical")
	if err != nil {
		return shim.Error("00004")
	}
	var statistical Statistical
	json.Unmarshal(state, &statistical)
	statistical.UploadFileNum = statistical.UploadFileNum + 1

	sBytes, err := json.Marshal(statistical)
	if err != nil {
		return shim.Error("00002")
	}

	err = stub.PutState("statistical", sBytes)

	return shim.Success(nil)
}
func (t *FileChain) readFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	if len(args) != 6 {
		return shim.Error("00001")
	}
	readChain := ReadChain{args[0], args[1], args[2], args[3], args[4], args[5]}
	bytes, err := json.Marshal(readChain)
	if err != nil {
		return shim.Error("00002")
	}
	err = stub.PutState("readFile_"+args[0], bytes)
	if err != nil {
		return shim.Error("00003")
	}

	state, err := stub.GetState("statistical")
	if err != nil {
		return shim.Error("00004")
	}
	var statistical Statistical
	json.Unmarshal(state, &statistical)
	statistical.ReadFileNum = statistical.ReadFileNum + 1

	sBytes, err := json.Marshal(statistical)
	if err != nil {
		return shim.Error("00002")
	}

	err = stub.PutState("statistical", sBytes)

	return shim.Success(nil)
}

/**download*/
func (t *FileChain) downloadFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	if len(args) != 8 {
		return shim.Error("00001")
	}
	fileChainDown := FileChainDown{
		args[0],
		args[1],
		args[2],
		args[3],
		args[4],
		args[5],
		args[6],
		args[7]}

	bytes, err := json.Marshal(fileChainDown)
	if err != nil {
		return shim.Error("00002")
	}
	err = stub.PutState("down_file"+args[0], bytes)

	down_file_num, err := stub.GetState("down_file_num" + args[0])
	if err != nil {
		return shim.Error("获取状态失败")
	}
	atoi, err := strconv.Atoi(string(down_file_num))
	num := atoi + 1
	err = stub.PutState("down_file_num"+args[0], []byte(strconv.Itoa(num)))
	if err != nil {
		return shim.Error("00003")
	}

	state, err := stub.GetState("statistical")
	if err != nil {
		return shim.Error("00004")
	}
	var statistical Statistical
	json.Unmarshal(state, &statistical)
	statistical.DownloadNum = statistical.DownloadNum + 1

	sBytes, err := json.Marshal(statistical)
	if err != nil {
		return shim.Error("00002")
	}

	err = stub.PutState("statistical", sBytes)
	return shim.Success(nil)
}

//delete ReadFile
func (t *FileChain) deleteReadFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("00001")
	}

	files := strings.Split(args[1], "&")
	waitChan := make(chan int)
	wait := sync.WaitGroup{}
	go func() {
		for _, file := range files {
			wait.Add(1)
			downFile := "readFile_" + file

			go func() {
				err := stub.DelState(downFile)
				if err != nil {
					return
				}
				wait.Done()
			}()
		}
		wait.Wait()
		waitChan <- 1
	}()
	<-waitChan
	return shim.Success(nil)
}

//delete UploadFile
func (t *FileChain) deleteUploadFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("00001")
	}

	files := strings.Split(args[1], "&")
	waitChan := make(chan int)
	wait := sync.WaitGroup{}
	go func() {
		for _, file := range files {
			wait.Add(1)
			downFile := "uploadFile_" + file

			go func() {
				err := stub.DelState(downFile)
				if err != nil {
					return
				}
				wait.Done()
			}()
		}
		wait.Wait()
		waitChan <- 1
	}()
	<-waitChan
	return shim.Success(nil)
}

//delete DownloadFile
func (t *FileChain) deleteDownloadFile(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("00001")
	}

	files := strings.Split(args[1], "&")
	waitChan := make(chan int)

	wait := sync.WaitGroup{}
	go func() {
		for _, file := range files {
			wait.Add(1)
			downFile := "down_file" + file

			go func() {
				err := stub.DelState(downFile)
				if err != nil {

					return
				}
				wait.Done()
			}()
		}
		wait.Wait()
		waitChan <- 1
	}()
	<-waitChan
	return shim.Success(nil)
}

func (t *FileChain) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("请输入至少1个参数")
	}
	index := 0
	for {
		key := args[index]
		valueBytes, err := stub.GetState(key)
		if err != nil {
			continue
		}
		_, err = strconv.Atoi(string(valueBytes))
		if err != nil {
			continue
		}
		if valueBytes != nil {
			err = stub.DelState(key)
			if err != nil {
				return shim.Error(err.Error())
			}
		}
		index++
		if index > len(args) {
			break
		}
	}
	return shim.Success(nil)
}

/**query callback preInfo data of a chaincode*/
func (t *FileChain) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	if len(args) != 1 {
		return shim.Error("00001")
	}

	info, err := stub.GetState(args[0])

	if err != nil {
		return shim.Error("00002")
	}
	return shim.Success(info)

}
func main() {
	err := shim.Start(new(FileChain))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
