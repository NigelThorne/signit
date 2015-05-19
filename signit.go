package main

import (
  "os"
  "os/exec"
  "os/user"
  "github.com/codegangsta/cli"
  "crypto/sha1"
  "bufio"
  "io"
  "path/filepath"
  "time"
  "fmt"
  "strings"
  "net/http"
  "net/url"
  "runtime"
  "encoding/base64"
)
    
func makeSig( user string, reason string, time time.Time, hash string) string{
    return fmt.Sprintf("Signatory: %s\nReason:    %s\nTime:      %v\nDoc Id:    %s", user, reason, time, hash)
}

func docToHash( filename string ) string {
    var f *os.File
    fullpath, err := filepath.Abs(filename)
    if err != nil {
        panic(err)
    }
    f, err = os.Open(fullpath)
    if err != nil {
        panic(err)
    }
    defer f.Close()
    reader := bufio.NewReader(f)
    sha1 := sha1.New()
    _, err = io.Copy(sha1, reader)
    if err != nil {
        panic(err)
    }
    return base64.URLEncoding.EncodeToString(sha1.Sum(nil))
}

func post(web_address, name, sig, hash string) {
    _, err := http.Post(web_address+"user/"+name+"/"+"signatures?sha="+ url.QueryEscape(hash), "text/text", strings.NewReader(sig))
    if err!=nil {
        println("**** Error posting to service ****")
        println(err.Error())
        panic(err)
    }
}

// func get_list(web_address, hash string) {
//     result, err := http.Get(web_address+"signatures/"+hash, "text/text")
//     if err!=nil {
//         println("**** Error posting to service ****")
//         println(err.Error())
//         panic(err)
//     }
//     return result
// }

func open_browser(url string)  error{
  var err error
  switch runtime.GOOS {
  case "linux":
      err = exec.Command("xdg-open", url).Start()
  case "darwin":
      err = exec.Command("open", url).Start()
  case "windows":
      err = exec.Command("C:\\Windows\\System32\\rundll32.exe", "url.dll,FileProtocolHandler", url).Start()
  default:
      err = fmt.Errorf("unsupported platform")
  }
  return err
}

func main() {
    app := cli.NewApp()
    app.Name = "SignIt"
    app.Commands = []cli.Command{
      {
        Name:  "sign",
        Aliases: []string{"s"},
        Usage: "Lodge your signature with a central signature repository",
        Flags: []cli.Flag {
          cli.StringFlag{ Name:"file, f", Value:"", Usage:"file to sign" },
          cli.StringFlag{ Name:"reason, r", Value:"Approving document for release.", Usage:"reason for signature" },
          cli.StringFlag{ Name:"service, url", Value:"http://localhost:51830/", Usage:"user-name of signatory" },
        },
        Action: func( c *cli.Context ) {

          //        if len(c.Args()) > 0 {
          //            name = c.Args()[0]
          defer func() { if r := recover(); r != nil {cli.ShowAppHelp(c)}}()

          hash := docToHash( c.String( "file" ) )
          name, err := user.Current()  
          if err!=nil {
            println(err.Error())
            panic(err)
          }         
          sig := makeSig( name.Name + " (" + name.Username + ")" , c.String( "reason" ), time.Now().Local(), hash) 
          println( sig )
          //    pass := prompt_for_password()
          post( c.String("service"), name.Username, sig, hash )
        },
      },
      {
        Name:  "list",
        Aliases: []string{"l"},
        Usage: "list all knows signatures for this document in the central signature repository",
        Flags: []cli.Flag {
          cli.StringFlag{ Name:"file, f", Value:"", Usage:"file to sign" },
          cli.StringFlag{ Name:"service, url", Value:"http://localhost:51830/", Usage:"user-name of signatory" },
        },
        Action: func( c *cli.Context ) {
          defer func() { if r := recover(); r != nil {cli.ShowAppHelp(c)}}()

          hash := docToHash( c.String( "file" ) )
          
          open_browser( c.String("service")+"signatures/"+url.QueryEscape(hash))
          //get_list( c.String("service"), hash)
        },
      },
    }

  app.Run(os.Args)
}

/*
Notes: 
    * installing HashTab means you can see the SHA1 of any file. 
TODO: 
   * Add config subcommand to configure the tool (url, username, ) like git.
   * prompt for password
   * use basic:auth
   * Show "You have signed this document" dialog.. with a link to the signature
   * report invalid config
*/
