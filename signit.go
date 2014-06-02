package main

import (
  "os"
  "github.com/codegangsta/cli"
  "crypto/sha1"
  "bufio"
  "io"
  "path/filepath"
  "time"
  "fmt"
  "strings"
  "net/http"
)
    
func makeSig( user string, reason string, time time.Time, hash []byte) string{
    return fmt.Sprintf("Signatory: %s\nReason:    %s\nTime:      %v\nDoc Id:    %x", user, reason, time, hash)
}

func docToHash( filename string ) []byte {
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
    return sha1.Sum(nil)
}

func post(url, name, sig string) {
    _, err := http.Post(url+"user/"+name+"/"+"signatures", "text/text", strings.NewReader(sig))
    if err!=nil {
        println("**** Error posting to service ****")
        println(err.Error())
        panic(err)
    }
}

func main() {
    app := cli.NewApp()
    app.Name = "SignIt"
    app.Usage = "Lodge your signature with a central signature repository"
    app.Flags = []cli.Flag {
        cli.StringFlag{ "file, f", "", "file to sign" },
        cli.StringFlag{ "reason, r", "Approving document for release.", "reason for signature" },
        cli.StringFlag{ "user, u", "", "user-name of signatory" },
        cli.StringFlag{ "service, url", "http://localhost:51830/", "user-name of signatory" },
    }
    app.Action = func( c *cli.Context ) {

//        if len(c.Args()) > 0 {
//            name = c.Args()[0]
    defer func() {
   			if r := recover(); r != nil {
                cli.ShowAppHelp(c)
   			}
   		}()
        hash := docToHash( c.String( "file" ) )
        sig := makeSig( c.String( "user" ), c.String( "reason" ), time.Now().Local(), hash) 
        println( sig )
    //    pass := prompt_for_password()
        post( c.String("service"), c.String( "user" ), sig )
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
