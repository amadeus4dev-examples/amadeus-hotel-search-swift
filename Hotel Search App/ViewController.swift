//
//  ViewController.swift
//  Amadeus SDK Hotel Search
//

import Amadeus
import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    var amadeus: Amadeus!
    @IBOutlet var cityInput: UITextField!
    @IBOutlet var checkInDate: UITextField!
    @IBOutlet var checkOutDate: UITextField!
    @IBOutlet var hotelResults: UITableView!

    let cityData: [(name: String, code: String)] = [("Amsterdam, Netherlands","AMS"), ("Atlanta, USA", "ATL"), ("Bangkok, Thailand", "BKK"), ("Barcelona, Spain", "BCN"), ("Beijing, China", "PEK"), ("Chicago, USA", "ORD"), ("Dallas, USA", "DFW"), ("Delhi, India", "DEL"), ("Denver, USA", "DEN"), ("Dubai, UAE", "DXB"), ("Frankfurt, Germany","FRA"), ("Guangzhou, China", "CAN"), ("Hong Kong", "HKG"), ("Jakarta,Indonesia", "CGK"), ("Kuala Lumpur, Malaysia", "KUL"), ("Las Vegas, USA", "LAS"), ("London, UK", "LHR"), ("Los Angeles, USA", "LAX"), ("Madrid, Spain", "MAD"), ("Miami, USA", "MIA"), ("Munich, Germany","MUC"), ("New York, USA", "JFK"), ("Paris, France", "CDG"), ("Seattle, USA", "SEA"), ("Seoul, South Korea", "ICN"), ("Shanghai, China", "PVG"), ("Singapore", "SIN"), ("Sydney, Australia", "SYD"), ("Tokyo, Japan", "HND"), ("Toronto, Canada", "YYZ"), ("San Francisco, USA", "SFO")]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        amadeus = Amadeus(client_id: "", client_secret: "")

        amadeus.referenceData.locations.get(data: ["subType": "AIRPORT,CITY",
                                                   "keyword": "r"], onCompletion: {
                result, _ in
                if result != nil {
                    print("Found \(result!.result["data"].arrayValue.count) Results")
                    for loc in result!.result["data"].arrayValue {
                        print(loc["address"]["cityName"].stringValue, loc["iataCode"].stringValue)
                    }
                }
        })

        let cityPicker = UIPickerView()
        cityPicker.delegate = self
        cityPicker.dataSource = self
        cityInput.inputView = cityPicker
        pickerView(cityPicker, didSelectRow: 0, inComponent: 0)

        let checkInDatePicker = UIDatePicker()
        checkInDatePicker.datePickerMode = .date
        checkInDatePicker.addTarget(self, action: #selector(setCheckInDate), for: .valueChanged)
        checkInDate.inputView = checkInDatePicker

        let checkOutDatePicker = UIDatePicker()
        checkOutDatePicker.datePickerMode = .date
        checkOutDatePicker.addTarget(self, action: #selector(setCheckOutDate), for: .valueChanged)
        checkOutDate.inputView = checkOutDatePicker

        setCheckInDate(sender: checkInDatePicker) // Set initial date

        hotelResults.delegate = self
        hotelResults.dataSource = self
    }

    @objc func setCheckInDate(sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        checkInDate.text = formatter.string(from: sender.date)
        // Automatically set the check-out date to the next day (Number of seconds in 1 day)
        checkOutDate.text = formatter.string(from: sender.date.advanced(by: 60 * 60 * 24))
    }

    @objc func setCheckOutDate(sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        checkOutDate.text = formatter.string(from: sender.date)
    }

    var searchResults: [(hotel: String, rating: String, offer: String, price: String)] = []

    @IBAction func onSearch(_: Any) {
        searchResults.removeAll()
        amadeus.shopping.hotelOffers.get(data: ["cityCode": cityCode,
                                                "checkInDate": checkInDate.text!,
                                                "checkOutDate": checkOutDate.text!]) { result, _ in
            if result != nil {
                print("Found \(result!.result["data"].arrayValue.count) Results")
                for hotel in result!.result["data"].arrayValue {
                    for offer in hotel["offers"].arrayValue {
                        self.searchResults.append((hotel: hotel["hotel"]["name"].stringValue, 
                                                   rating: hotel["hotel"]["rating"].stringValue, 
                                                   offer: offer["room"]["description"]["text"].stringValue,
                                                   price: offer["price"]["total"].stringValue))
                    }
                }
            }
            DispatchQueue.main.async {
                self.hotelResults.reloadData()
            }
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return searchResults.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = hotelResults.dequeueReusableCell(withIdentifier: "offerCell", for: indexPath)
        let offer = searchResults[indexPath.row]
        cell.textLabel?.text = "\(offer.price) - \(offer.hotel) (\(offer.rating) Star)"
        cell.detailTextLabel?.text = "\(offer.offer)"
        return cell
    }

    var cityCode: String = ""

    func numberOfComponents(in _: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        return cityData.count
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        cityInput.text = cityData[row].name
        cityCode = cityData[row].code
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        return cityData[row].name
    }
}
