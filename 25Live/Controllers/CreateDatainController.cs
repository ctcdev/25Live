using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using _25Live.Models;
using Newtonsoft.Json.Linq;
using System.IO;

namespace _25Live.Controllers
{
    public class CreateDatainController : Controller
    {
        // GET: CreateDatain
        public ActionResult Index()
        {
            return View("Index");
        }
        public ActionResult CreateNewFile(String yearQuarter)
        {
            ctrl obj = new ctrl();
            IDictionary<string, string> dict = obj.createDataInFile(yearQuarter);
            string status = dict["status"]; 
           
            if ((String.Compare(status, "success", true)) == 0)
            {
                string message = dict["message"];
                Session["message"] = message;
                return View("Datain");
            }
            else
            {
                string exception = dict["message"];
                Session["exception"] = exception;
                return View("ExceptionOccured");
            }
        }
    }
}