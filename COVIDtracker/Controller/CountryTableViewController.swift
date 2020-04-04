//
//  CountryTableViewController.swift
//  COVIDtracker
//
//  Created by Prakhar Prakash Bhardwaj on 29/03/20.
//  Copyright © 2020 Prakhar Prakash Bhardwaj. All rights reserved.
//

import UIKit

class CountryTableViewController: UITableViewController {
    
    @IBOutlet weak var totalCases: UILabel!
    @IBOutlet weak var newCases: UILabel!
    @IBOutlet weak var totalDeaths: UILabel!
    @IBOutlet weak var newDeaths: UILabel!
    @IBOutlet weak var totalRecovered: UILabel!
    @IBOutlet weak var activeCases: UILabel!
    
    var countryData = [CountryData]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var _country: String = "-"
    var _totalCases: String = "-"
    var _newCases: String = "-"
    var _totalDeaths: String = "-"
    var _newDeaths: String = "-"
    var _totalRecovered: String = "-"
    var _activeCases: String = "-"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = _country
        
        DispatchQueue.main.async {
            self.generateSession()
        }
        
    }
    
    func loading(){
        DispatchQueue.main.async {
            self.appDelegate.showProcessingIndicatorOnView(vwBg: self.view, title: "")
            self.tableView.isUserInteractionEnabled = false
        }
    }
    
    func stopLoading(){
        DispatchQueue.main.async {
            self.appDelegate.hideProcessingIndicatorFromView(vwBg: self.view)
            self.tableView.isUserInteractionEnabled = true
        }
    }
    
    func generateSession() {
        getdataApi { (res) in
            switch res {
            case .success(let jsonResult):
                DispatchQueue.main.async {
                    self.countryData = [jsonResult as! CountryData]
                    
                    self._totalCases = self.countryData[0].totalCases
                    self._newCases = self.countryData[0].newCases
                    self._totalDeaths = self.countryData[0].totalDeaths
                    self._newDeaths = self.countryData[0].newDeaths
                    self._totalRecovered = self.countryData[0].totalRecovered
                    self._activeCases = self.countryData[0].activeCases
                    
                    if(self._totalCases.isEmpty){
                        self._totalCases = "0"
                    } else if(self._newCases.isEmpty){
                        self._newCases = "0"
                    } else if (self._totalDeaths.isEmpty){
                        self._totalDeaths = "0"
                    } else if (self._newDeaths.isEmpty){
                        self._newDeaths = "0"
                    } else if (self._totalRecovered.isEmpty){
                        self._totalRecovered = "0"
                    } else if (self._activeCases.isEmpty){
                        self._activeCases = "0"
                    }
                    
                    self.totalCases.text = self._totalCases
                    self.newCases.text = self._newCases
                    self.totalDeaths.text = self._totalDeaths
                    self.newDeaths.text = self._newDeaths
                    self.totalRecovered.text = self._totalRecovered
                    self.activeCases.text = self._activeCases
                    self.tableView.reloadData()
                    self.stopLoading()
                }
            case .failure(let err):
                print("Failed to fetch courses", err.localizedDescription)
                self.stopLoading()
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Oops!", message: "Please check your internet connection", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(ac, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getdataApi(completion: @escaping (Result<Any, Error>) -> Void) {
        self.loading()
        self.countryData.removeAll()
        
        let urlString = "https://prakhar-covid19-api.herokuapp.com/covid19/search?country=\(_country)"
        
        guard let _urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        let urlPath = URL(string: _urlString)!
        let urlRequest = URLRequest(url: urlPath)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let data = data else { return }
            do {
                let courses = try JSONDecoder().decode(CountryData.self, from: data)
                completion(.success(courses))
                print(CountryData.self)
                print(courses)
                print(data)
            } catch let jsonError {
                completion(.failure(jsonError))
            }        }
        task.resume()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }
    
}
